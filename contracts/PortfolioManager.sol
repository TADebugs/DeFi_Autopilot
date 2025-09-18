// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title PortfolioManager
 * @dev Core contract for managing DeFi portfolios with AI-powered optimization
 */
contract PortfolioManager is ReentrancyGuard, Pausable, Ownable {
    using SafeMath for uint256;

    // Risk profiles
    enum RiskProfile { CONSERVATIVE, BALANCED, AGGRESSIVE }
    
    // Portfolio structure
    struct Portfolio {
        uint256 totalValue;
        uint256 currentYield; // APY in basis points (100 = 1%)
        string currentProtocol;
        RiskProfile riskProfile;
        bool autoRebalanceEnabled;
        uint256 lastRebalance;
        uint256 totalProfit;
    }
    
    // Events
    event PortfolioCreated(address indexed user, uint256 amount, RiskProfile riskProfile);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event PortfolioRebalanced(address indexed user, string fromProtocol, string toProtocol, uint256 expectedYield);
    event RiskProfileUpdated(address indexed user, RiskProfile oldProfile, RiskProfile newProfile);
    event AutoRebalanceToggled(address indexed user, bool enabled);
    
    // State variables
    mapping(address => Portfolio) public portfolios;
    mapping(address => bool) public authorizedRebalancers;
    
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    uint256 public constant MIN_YIELD_IMPROVEMENT = 50; // 0.5% in basis points
    uint256 public constant MAX_GAS_THRESHOLD = 0.02 ether;
    
    modifier onlyAuthorizedRebalancer() {
        require(authorizedRebalancers[msg.sender], "Not authorized rebalancer");
        _;
    }
    
    /**
     * @dev Create a new portfolio with initial deposit
     * @param riskProfile User's risk tolerance (0=Conservative, 1=Balanced, 2=Aggressive)
     */
    function createPortfolio(uint8 riskProfile) external payable whenNotPaused {
        require(msg.value >= MIN_DEPOSIT, "Minimum deposit required");
        require(riskProfile <= 2, "Invalid risk profile");
        require(portfolios[msg.sender].totalValue == 0, "Portfolio already exists");
        
        portfolios[msg.sender] = Portfolio({
            totalValue: msg.value,
            currentYield: 320, // Starting at 3.2% APY (Aave example)
            currentProtocol: "Aave",
            riskProfile: RiskProfile(riskProfile),
            autoRebalanceEnabled: true,
            lastRebalance: block.timestamp,
            totalProfit: 0
        });
        
        emit PortfolioCreated(msg.sender, msg.value, RiskProfile(riskProfile));
    }
    
    /**
     * @dev Deposit additional funds to existing portfolio
     */
    function depositFunds() external payable nonReentrant whenNotPaused {
        require(portfolios[msg.sender].totalValue > 0, "Portfolio does not exist");
        require(msg.value > 0, "Amount must be greater than 0");
        
        portfolios[msg.sender].totalValue = portfolios[msg.sender].totalValue.add(msg.value);
        
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw funds from portfolio
     * @param amount Amount to withdraw in wei
     */
    function withdrawFunds(uint256 amount) external nonReentrant whenNotPaused {
        require(portfolios[msg.sender].totalValue >= amount, "Insufficient balance");
        require(amount > 0, "Amount must be greater than 0");
        
        portfolios[msg.sender].totalValue = portfolios[msg.sender].totalValue.sub(amount);
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsWithdrawn(msg.sender, amount);
    }
    
    /**
     * @dev Update user's risk profile
     * @param newProfile New risk profile (0-2)
     */
    function updateRiskProfile(uint8 newProfile) external whenNotPaused {
        require(newProfile <= 2, "Invalid risk profile");
        require(portfolios[msg.sender].totalValue > 0, "Portfolio does not exist");
        
        RiskProfile oldProfile = portfolios[msg.sender].riskProfile;
        portfolios[msg.sender].riskProfile = RiskProfile(newProfile);
        
        emit RiskProfileUpdated(msg.sender, oldProfile, RiskProfile(newProfile));
    }
    
    /**
     * @dev Toggle auto-rebalancing for portfolio
     */
    function toggleAutoRebalance() external whenNotPaused {
        require(portfolios[msg.sender].totalValue > 0, "Portfolio does not exist");
        
        portfolios[msg.sender].autoRebalanceEnabled = !portfolios[msg.sender].autoRebalanceEnabled;
        
        emit AutoRebalanceToggled(msg.sender, portfolios[msg.sender].autoRebalanceEnabled);
    }
    
    /**
     * @dev Execute portfolio rebalancing (called by AI engine)
     * @param user User's address
     * @param fromProtocol Current protocol
     * @param toProtocol Target protocol
     * @param expectedYield Expected new yield in basis points
     * @param gasCost Estimated gas cost for the operation
     */
    function executeRebalance(
        address user,
        string memory fromProtocol,
        string memory toProtocol,
        uint256 expectedYield,
        uint256 gasCost
    ) external onlyAuthorizedRebalancer whenNotPaused {
        require(portfolios[user].totalValue > 0, "Portfolio does not exist");
        require(portfolios[user].autoRebalanceEnabled, "Auto-rebalance disabled");
        require(gasCost <= MAX_GAS_THRESHOLD, "Gas cost too high");
        
        // Check profitability
        require(
            checkRebalanceProfitability(user, expectedYield, gasCost),
            "Rebalancing not profitable"
        );
        
        // Update portfolio
        portfolios[user].currentProtocol = toProtocol;
        portfolios[user].currentYield = expectedYield;
        portfolios[user].lastRebalance = block.timestamp;
        
        // Calculate and add profit (simplified calculation)
        uint256 yieldDifference = expectedYield.sub(portfolios[user].currentYield);
        uint256 annualProfit = portfolios[user].totalValue.mul(yieldDifference).div(10000);
        uint256 netProfit = annualProfit.sub(gasCost);
        portfolios[user].totalProfit = portfolios[user].totalProfit.add(netProfit);
        
        emit PortfolioRebalanced(user, fromProtocol, toProtocol, expectedYield);
    }
    
    /**
     * @dev Check if rebalancing would be profitable
     * @param user User's address
     * @param newYield New expected yield in basis points
     * @param gasCost Estimated gas cost
     * @return bool Whether rebalancing is profitable
     */
    function checkRebalanceProfitability(
        address user,
        uint256 newYield,
        uint256 gasCost
    ) public view returns (bool) {
        Portfolio memory portfolio = portfolios[user];
        
        if (newYield <= portfolio.currentYield.add(MIN_YIELD_IMPROVEMENT)) {
            return false;
        }
        
        uint256 yieldImprovement = newYield.sub(portfolio.currentYield);
        uint256 annualProfit = portfolio.totalValue.mul(yieldImprovement).div(10000);
        
        // Require 15% margin above execution costs
        uint256 requiredProfit = gasCost.mul(115).div(100);
        
        return annualProfit >= requiredProfit;
    }
    
    /**
     * @dev Get portfolio information for a user
     * @param user User's address
     * @return totalValue Portfolio total value
     * @return currentYield Current yield percentage
     * @return currentProtocol Current protocol name
     * @return riskProfile Risk profile setting
     * @return autoRebalanceEnabled Auto-rebalance status
     * @return lastRebalance Last rebalance timestamp
     * @return totalProfit Total profit generated
     */
    function getPortfolio(address user) external view returns (
        uint256 totalValue,
        uint256 currentYield,
        string memory currentProtocol,
        RiskProfile riskProfile,
        bool autoRebalanceEnabled,
        uint256 lastRebalance,
        uint256 totalProfit
    ) {
        Portfolio memory portfolio = portfolios[user];
        return (
            portfolio.totalValue,
            portfolio.currentYield,
            portfolio.currentProtocol,
            portfolio.riskProfile,
            portfolio.autoRebalanceEnabled,
            portfolio.lastRebalance,
            portfolio.totalProfit
        );
    }
    
    /**
     * @dev Authorize/deauthorize AI rebalancer
     * @param aiEngine Address of the AI engine
     * @param authorized Whether to authorize or deauthorize
     */
    function authorizeRebalancer(address aiEngine, bool authorized) external onlyOwner {
        authorizedRebalancers[aiEngine] = authorized;
    }
    
    /**
     * @dev Emergency pause function
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause function
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }
}
