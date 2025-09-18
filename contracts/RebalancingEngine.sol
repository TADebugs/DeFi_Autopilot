// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PortfolioManager.sol";
import "./YieldOracle.sol";

/**
 * @title RebalancingEngine
 * @dev AI-driven rebalancing engine that executes portfolio optimizations
 * Integrates with PortfolioManager and YieldOracle for intelligent rebalancing
 */
contract RebalancingEngine is Ownable, Pausable, ReentrancyGuard {
    
    PortfolioManager public portfolioManager;
    YieldOracle public yieldOracle;
    
    struct RebalanceRequest {
        address user;
        string fromProtocol;
        string toProtocol;
        uint256 amount;
        uint256 expectedYield;
        uint256 estimatedGas;
        uint256 timestamp;
        bool executed;
        bool cancelled;
    }
    
    struct OptimizationMetrics {
        uint256 totalRebalances;
        uint256 totalProfitGenerated;
        uint256 totalGasSaved;
        uint256 averageYieldImprovement;
        uint256 lastOptimizationRun;
    }
    
    // State variables
    mapping(uint256 => RebalanceRequest) public rebalanceRequests;
    mapping(address => uint256[]) public userRebalanceHistory;
    mapping(address => bool) public authorizedAIEngines;
    
    OptimizationMetrics public metrics;
    uint256 public requestCounter;
    
    // Constants for profitability calculations
    uint256 public constant MIN_PROFIT_THRESHOLD = 100; // 1% minimum profit in basis points
    uint256 public constant MAX_GAS_COST = 0.02 ether; // Maximum gas cost threshold
    uint256 public constant PROFIT_MARGIN_REQUIREMENT = 1150; // 15% margin requirement (11.5x multiplier)
    uint256 public constant REBALANCE_COOLDOWN = 1 hours; // Minimum time between rebalances
    
    // Events
    event RebalanceRequested(
        uint256 indexed requestId,
        address indexed user,
        string fromProtocol,
        string toProtocol,
        uint256 expectedYield
    );
    
    event RebalanceExecuted(
        uint256 indexed requestId,
        address indexed user,
        string fromProtocol,
        string toProtocol,
        uint256 amount,
        uint256 actualYield,
        uint256 profit
    );
    
    event RebalanceCancelled(uint256 indexed requestId, string reason);
    event AIEngineAuthorized(address indexed aiEngine, bool authorized);
    event OptimizationCompleted(uint256 usersOptimized, uint256 totalProfit);
    
    modifier onlyAuthorizedAI() {
        require(authorizedAIEngines[msg.sender] || msg.sender == owner(), "Not authorized AI engine");
        _;
    }
    
    modifier validRequest(uint256 _requestId) {
        require(_requestId < requestCounter, "Invalid request ID");
        require(!rebalanceRequests[_requestId].executed, "Request already executed");
        require(!rebalanceRequests[_requestId].cancelled, "Request cancelled");
        _;
    }
    
    constructor(address _portfolioManager, address _yieldOracle) {
        require(_portfolioManager != address(0), "Invalid portfolio manager");
        require(_yieldOracle != address(0), "Invalid yield oracle");
        
        portfolioManager = PortfolioManager(_portfolioManager);
        yieldOracle = YieldOracle(_yieldOracle);
        
        // Initialize metrics
        metrics.lastOptimizationRun = block.timestamp;
    }
    
    /**
     * @dev Request a portfolio rebalance (called by AI engine)
     * @param _user User address
     * @param _fromProtocol Current protocol
     * @param _toProtocol Target protocol
     * @param _expectedYield Expected new yield in basis points
     * @param _estimatedGas Estimated gas cost for execution
     * @return requestId Unique identifier for the rebalance request
     */
    function requestRebalance(
        address _user,
        string calldata _fromProtocol,
        string calldata _toProtocol,
        uint256 _expectedYield,
        uint256 _estimatedGas
    ) 
        external 
        onlyAuthorizedAI 
        whenNotPaused 
        returns (uint256 requestId) 
    {
        require(_user != address(0), "Invalid user address");
        require(_estimatedGas <= MAX_GAS_COST, "Gas cost too high");
        require(bytes(_fromProtocol).length > 0, "Empty from protocol");
        require(bytes(_toProtocol).length > 0, "Empty to protocol");
        
        // Get user portfolio information
        (
            uint256 totalValue,
            uint256 currentYield,
            string memory currentProtocol,
            PortfolioManager.RiskProfile riskProfile,
            bool autoEnabled,
            ,
            
        ) = portfolioManager.getPortfolio(_user);
        
        // Check if portfolio exists and auto-rebalance is enabled
        require(autoEnabled, "Auto-rebalance disabled");
        require(totalValue > 0, "Empty portfolio");
        
        // Validate protocol transition
        require(
            keccak256(bytes(currentProtocol)) == keccak256(bytes(_fromProtocol)),
            "From protocol mismatch"
        );
        
        // Check profitability
        require(
            _isProfitableRebalance(_user, currentYield, _expectedYield, _estimatedGas, totalValue),
            "Rebalancing not profitable"
        );
        
        // Check cooldown period
        uint256[] memory userHistory = userRebalanceHistory[_user];
        if (userHistory.length > 0) {
            uint256 lastRequestId = userHistory[userHistory.length - 1];
            require(
                block.timestamp - rebalanceRequests[lastRequestId].timestamp >= REBALANCE_COOLDOWN,
                "Cooldown period active"
            );
        }
        
        // Create rebalance request
        requestId = requestCounter++;
        rebalanceRequests[requestId] = RebalanceRequest({
            user: _user,
            fromProtocol: _fromProtocol,
            toProtocol: _toProtocol,
            amount: totalValue,
            expectedYield: _expectedYield,
            estimatedGas: _estimatedGas,
            timestamp: block.timestamp,
            executed: false,
            cancelled: false
        });
        
        userRebalanceHistory[_user].push(requestId);
        
        emit RebalanceRequested(requestId, _user, _fromProtocol, _toProtocol, _expectedYield);
        
        return requestId;
    }
    
    /**
     * @dev Execute a rebalance request
     * @param _requestId Request identifier
     */
    function executeRebalance(uint256 _requestId) 
        external 
        onlyAuthorizedAI 
        nonReentrant 
        validRequest(_requestId) 
        whenNotPaused 
    {
        RebalanceRequest storage request = rebalanceRequests[_requestId];
        
        // Double-check profitability before execution
        (
            uint256 totalValue,
            uint256 currentYield,
            ,
            ,
            bool autoEnabled,
            ,
            
        ) = portfolioManager.getPortfolio(request.user);
        
        require(autoEnabled, "Auto-rebalance disabled");
        require(
            _isProfitableRebalance(
                request.user, 
                currentYield, 
                request.expectedYield, 
                request.estimatedGas,
                totalValue
            ),
            "No longer profitable"
        );
        
        // Execute the rebalance through PortfolioManager
        try portfolioManager.executeRebalance(
            request.user,
            request.fromProtocol,
            request.toProtocol,
            request.expectedYield,
            request.estimatedGas
        ) {
            // Mark as executed
            request.executed = true;
            
            // Update metrics
            _updateMetrics(request, currentYield);
            
            emit RebalanceExecuted(
                _requestId,
                request.user,
                request.fromProtocol,
                request.toProtocol,
                request.amount,
                request.expectedYield,
                _calculateProfit(currentYield, request.expectedYield, totalValue, request.estimatedGas)
            );
            
        } catch Error(string memory reason) {
            // Cancel the request if execution fails
            request.cancelled = true;
            emit RebalanceCancelled(_requestId, reason);
        }
    }
    
    /**
     * @dev Cancel a pending rebalance request
     * @param _requestId Request identifier
     * @param _reason Cancellation reason
     */
    function cancelRebalance(uint256 _requestId, string calldata _reason) 
        external 
        onlyAuthorizedAI 
        validRequest(_requestId) 
    {
        rebalanceRequests[_requestId].cancelled = true;
        emit RebalanceCancelled(_requestId, _reason);
    }
    
    /**
     * @dev Batch optimization for multiple users
     * @param _users Array of user addresses to optimize
     */
    function batchOptimization(address[] calldata _users) 
        external 
        onlyAuthorizedAI 
        whenNotPaused 
    {
        uint256 optimizedCount = 0;
        uint256 totalProfit = 0;
        
        for (uint256 i = 0; i < _users.length; i++) {
            address user = _users[i];
            
            // Get user portfolio
            (
                uint256 totalValue,
                uint256 currentYield,
                string memory currentProtocol,
                PortfolioManager.RiskProfile riskProfile,
                bool autoEnabled,
                ,
                
            ) = portfolioManager.getPortfolio(user);
            
            if (!autoEnabled || totalValue == 0) {
                continue;
            }
            
            // Find best yield opportunity
            (
                string memory bestProtocol,
                uint256 bestYield,
                uint8 bestRiskScore
            ) = yieldOracle.getBestYieldForRisk(
                _mapRiskProfile(uint8(riskProfile)),
                50000000 * 1e18 // $50M minimum TVL
            );
            
            // Check if optimization is worthwhile
            if (
                bytes(bestProtocol).length > 0 &&
                bestYield > currentYield &&
                bestRiskScore <= _mapRiskProfile(uint8(riskProfile))
            ) {
                uint256 estimatedGas = _estimateGasCost(currentProtocol, bestProtocol);
                
                if (_isProfitableRebalance(user, currentYield, bestYield, estimatedGas, totalValue)) {
                    // Create rebalance request
                    try this.requestRebalance(
                        user,
                        currentProtocol,
                        bestProtocol,
                        bestYield,
                        estimatedGas
                    ) returns (uint256 requestId) {
                        // Execute immediately if requested
                        this.executeRebalance(requestId);
                        optimizedCount++;
                        totalProfit += _calculateProfit(currentYield, bestYield, totalValue, estimatedGas);
                    } catch {
                        // Skip this user if optimization fails
                        continue;
                    }
                }
            }
        }
        
        metrics.lastOptimizationRun = block.timestamp;
        emit OptimizationCompleted(optimizedCount, totalProfit);
    }
    
    /**
     * @dev Check if a rebalance would be profitable
     * @param _user User address
     * @param _currentYield Current yield in basis points
     * @param _newYield New expected yield in basis points
     * @param _gasCost Estimated gas cost
     * @param _portfolioValue Portfolio value
     * @return profitable Whether the rebalance is profitable
     */
    function isProfitableRebalance(
        address _user,
        uint256 _currentYield,
        uint256 _newYield,
        uint256 _gasCost,
        uint256 _portfolioValue
    ) external view returns (bool profitable) {
        return _isProfitableRebalance(_user, _currentYield, _newYield, _gasCost, _portfolioValue);
    }
    
    /**
     * @dev Get rebalance request details
     * @param _requestId Request identifier
     * @return request RebalanceRequest struct
     */
    function getRebalanceRequest(uint256 _requestId) 
        external 
        view 
        returns (RebalanceRequest memory request) 
    {
        require(_requestId < requestCounter, "Invalid request ID");
        return rebalanceRequests[_requestId];
    }
    
    /**
     * @dev Get user's rebalance history
     * @param _user User address
     * @return requestIds Array of request IDs
     */
    function getUserRebalanceHistory(address _user) 
        external 
        view 
        returns (uint256[] memory requestIds) 
    {
        return userRebalanceHistory[_user];
    }
    
    /**
     * @dev Get optimization metrics
     * @return OptimizationMetrics struct
     */
    function getOptimizationMetrics() external view returns (OptimizationMetrics memory) {
        return metrics;
    }
    
    // Admin functions
    function authorizeAIEngine(address _aiEngine, bool _authorized) 
        external 
        onlyOwner 
    {
        authorizedAIEngines[_aiEngine] = _authorized;
        emit AIEngineAuthorized(_aiEngine, _authorized);
    }
    
    function setPortfolioManager(address _portfolioManager) external onlyOwner {
        require(_portfolioManager != address(0), "Invalid address");
        portfolioManager = PortfolioManager(_portfolioManager);
    }
    
    function setYieldOracle(address _yieldOracle) external onlyOwner {
        require(_yieldOracle != address(0), "Invalid address");
        yieldOracle = YieldOracle(_yieldOracle);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Internal functions
    function _isProfitableRebalance(
        address _user,
        uint256 _currentYield,
        uint256 _newYield,
        uint256 _gasCost,
        uint256 _portfolioValue
    ) internal pure returns (bool) {
        if (_newYield <= _currentYield) {
            return false;
        }
        
        uint256 yieldImprovement = _newYield - _currentYield;
        uint256 annualProfit = (_portfolioValue * yieldImprovement) / 10000;
        uint256 requiredProfit = (_gasCost * PROFIT_MARGIN_REQUIREMENT) / 1000;
        
        return annualProfit >= requiredProfit;
    }
    
    function _calculateProfit(
        uint256 _currentYield,
        uint256 _newYield,
        uint256 _portfolioValue,
        uint256 _gasCost
    ) internal pure returns (uint256) {
        if (_newYield <= _currentYield) {
            return 0;
        }
        
        uint256 yieldImprovement = _newYield - _currentYield;
        uint256 annualProfit = (_portfolioValue * yieldImprovement) / 10000;
        
        return annualProfit > _gasCost ? annualProfit - _gasCost : 0;
    }
    
    function _updateMetrics(RebalanceRequest storage _request, uint256 _oldYield) internal {
        metrics.totalRebalances++;
        
        uint256 profit = _calculateProfit(_oldYield, _request.expectedYield, _request.amount, _request.estimatedGas);
        metrics.totalProfitGenerated += profit;
        
        uint256 yieldImprovement = _request.expectedYield > _oldYield ? 
            _request.expectedYield - _oldYield : 0;
        
        // Update average yield improvement (simple moving average)
        metrics.averageYieldImprovement = 
            (metrics.averageYieldImprovement * (metrics.totalRebalances - 1) + yieldImprovement) / 
            metrics.totalRebalances;
    }
    
    function _mapRiskProfile(uint8 _portfolioRisk) internal pure returns (uint8) {
        // Map portfolio risk profile to oracle risk tolerance
        if (_portfolioRisk == 1) return 3;      // Conservative -> max risk 3
        if (_portfolioRisk == 2) return 5;      // Balanced -> max risk 5  
        if (_portfolioRisk == 3) return 8;      // Aggressive -> max risk 8
        return 5; // Default to balanced
    }
    
    function _estimateGasCost(
        string memory _fromProtocol,
        string memory _toProtocol
    ) internal pure returns (uint256) {
        // Simplified gas estimation based on protocol complexity
        // In production, this would use actual gas estimation
        
        bytes32 fromHash = keccak256(bytes(_fromProtocol));
        bytes32 toHash = keccak256(bytes(_toProtocol));
        
        // Base gas cost
        uint256 baseCost = 0.005 ether;
        
        // Add complexity based on protocols
        if (fromHash == keccak256(bytes("Curve")) || toHash == keccak256(bytes("Curve"))) {
            baseCost += 0.003 ether; // Curve is more complex
        }
        
        if (fromHash == keccak256(bytes("Yearn")) || toHash == keccak256(bytes("Yearn"))) {
            baseCost += 0.002 ether; // Yearn strategies add complexity
        }
        
        return baseCost;
    }
}
