// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title YieldOracle
 * @dev Oracle contract for fetching and managing DeFi protocol yield data
 * Integrates with Flare Network oracles for real-time data feeds
 */
contract YieldOracle is Ownable, Pausable {
    
    struct YieldData {
        string protocol;
        uint256 apy; // APY in basis points (10000 = 100%)
        uint256 tvl; // Total Value Locked in USD (scaled by 1e18)
        uint8 riskScore; // Risk score 1-10 (1=safest, 10=riskiest)
        uint256 timestamp;
        bool active;
    }

    struct HistoricalYield {
        uint256 apy;
        uint256 timestamp;
    }

    // State variables
    mapping(string => YieldData) public protocolYields;
    mapping(string => HistoricalYield[]) public yieldHistory;
    mapping(address => bool) public authorizedUpdaters;
    
    string[] public supportedProtocols;
    uint256 public constant MAX_STALENESS = 3600; // 1 hour max data staleness
    uint256 public constant MIN_TVL_THRESHOLD = 1000000 * 1e18; // $1M minimum TVL

    // Events
    event YieldUpdated(
        string indexed protocol,
        uint256 newApy,
        uint256 tvl,
        uint8 riskScore,
        uint256 timestamp
    );
    
    event ProtocolAdded(string protocol, uint8 riskScore);
    event ProtocolDeactivated(string protocol, string reason);
    event UpdaterAuthorized(address indexed updater, bool authorized);

    modifier onlyAuthorizedUpdater() {
        require(authorizedUpdaters[msg.sender] || msg.sender == owner(), "Not authorized");
        _;
    }

    modifier validProtocol(string calldata _protocol) {
        require(protocolYields[_protocol].active, "Protocol not active");
        _;
    }

    constructor() {
        // Initialize with major DeFi protocols
        _addProtocol("Aave", 2);
        _addProtocol("Compound", 2);
        _addProtocol("Curve", 3);
        _addProtocol("Uniswap", 4);
        _addProtocol("Yearn", 3);
        _addProtocol("Convex", 4);
        _addProtocol("Lido", 2);
        _addProtocol("Rocket Pool", 3);
    }

    /**
     * @dev Update yield data for a specific protocol
     * @param _protocol Protocol name
     * @param _apy Annual Percentage Yield in basis points
     * @param _tvl Total Value Locked in USD (scaled by 1e18)
     * @param _riskScore Risk assessment score (1-10)
     */
    function updateYield(
        string calldata _protocol,
        uint256 _apy,
        uint256 _tvl,
        uint8 _riskScore
    ) 
        external 
        onlyAuthorizedUpdater 
        validProtocol(_protocol) 
        whenNotPaused 
    {
        require(_riskScore >= 1 && _riskScore <= 10, "Invalid risk score");
        require(_apy <= 50000, "APY too high (>500%)"); // Sanity check
        require(_tvl >= MIN_TVL_THRESHOLD, "TVL below minimum");

        YieldData storage yieldData = protocolYields[_protocol];
        
        // Store historical data
        yieldHistory[_protocol].push(HistoricalYield({
            apy: yieldData.apy,
            timestamp: yieldData.timestamp
        }));

        // Update current data
        yieldData.apy = _apy;
        yieldData.tvl = _tvl;
        yieldData.riskScore = _riskScore;
        yieldData.timestamp = block.timestamp;

        emit YieldUpdated(_protocol, _apy, _tvl, _riskScore, block.timestamp);
    }

    /**
     * @dev Get the best yield opportunity for a given risk profile
     * @param _riskProfile Maximum acceptable risk score
     * @param _minTvl Minimum required TVL
     * @return bestProtocol Name of the best protocol
     * @return bestYield APY of the best protocol
     * @return riskScore Risk score of the best protocol
     */
    function getBestYieldForRisk(
        uint8 _riskProfile,
        uint256 _minTvl
    ) 
        external 
        view 
        returns (
            string memory bestProtocol,
            uint256 bestYield,
            uint8 riskScore
        ) 
    {
        require(_riskProfile >= 1 && _riskProfile <= 10, "Invalid risk profile");
        
        uint256 highestYield = 0;
        string memory topProtocol;
        uint8 topRiskScore;

        for (uint256 i = 0; i < supportedProtocols.length; i++) {
            string memory protocol = supportedProtocols[i];
            YieldData memory data = protocolYields[protocol];
            
            if (
                data.active &&
                data.riskScore <= _riskProfile &&
                data.tvl >= _minTvl &&
                data.apy > highestYield &&
                !_isStaleData(data.timestamp)
            ) {
                highestYield = data.apy;
                topProtocol = protocol;
                topRiskScore = data.riskScore;
            }
        }

        return (topProtocol, highestYield, topRiskScore);
    }

    /**
     * @dev Get yield data for a specific protocol
     * @param _protocol Protocol name
     * @return apy Current APY in basis points
     * @return tvl Total Value Locked
     * @return riskScore Risk assessment score
     * @return timestamp Last update timestamp
     * @return active Whether protocol is active
     */
    function getProtocolYield(string calldata _protocol) 
        external 
        view 
        returns (
            uint256 apy,
            uint256 tvl,
            uint8 riskScore,
            uint256 timestamp,
            bool active
        ) 
    {
        YieldData memory data = protocolYields[_protocol];
        return (data.apy, data.tvl, data.riskScore, data.timestamp, data.active);
    }

    /**
     * @dev Get all active protocols with their yield data
     * @return protocols Array of protocol names
     * @return apys Array of APYs
     * @return riskScores Array of risk scores
     */
    function getAllActiveYields() 
        external 
        view 
        returns (
            string[] memory protocols,
            uint256[] memory apys,
            uint8[] memory riskScores
        ) 
    {
        uint256 activeCount = _getActiveProtocolCount();
        
        protocols = new string[](activeCount);
        apys = new uint256[](activeCount);
        riskScores = new uint8[](activeCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < supportedProtocols.length; i++) {
            string memory protocol = supportedProtocols[i];
            YieldData memory data = protocolYields[protocol];
            
            if (data.active && !_isStaleData(data.timestamp)) {
                protocols[index] = protocol;
                apys[index] = data.apy;
                riskScores[index] = data.riskScore;
                index++;
            }
        }
    }

    /**
     * @dev Compare yields between two protocols
     * @param _protocol1 First protocol
     * @param _protocol2 Second protocol
     * @return betterProtocol Name of protocol with better risk-adjusted yield
     * @return yieldDifference Yield difference in basis points
     */
    function compareProtocols(
        string calldata _protocol1,
        string calldata _protocol2
    ) 
        external 
        view 
        returns (
            string memory betterProtocol,
            uint256 yieldDifference
        ) 
    {
        YieldData memory data1 = protocolYields[_protocol1];
        YieldData memory data2 = protocolYields[_protocol2];
        
        require(data1.active && data2.active, "One or both protocols inactive");
        require(!_isStaleData(data1.timestamp) && !_isStaleData(data2.timestamp), "Stale data");

        // Calculate risk-adjusted yield (simple risk adjustment)
        uint256 adjustedYield1 = (data1.apy * 10) / (data1.riskScore + 1);
        uint256 adjustedYield2 = (data2.apy * 10) / (data2.riskScore + 1);

        if (adjustedYield1 > adjustedYield2) {
            return (_protocol1, data1.apy > data2.apy ? data1.apy - data2.apy : 0);
        } else {
            return (_protocol2, data2.apy > data1.apy ? data2.apy - data1.apy : 0);
        }
    }

    /**
     * @dev Get historical yield data for a protocol
     * @param _protocol Protocol name
     * @param _limit Maximum number of historical records to return
     * @return apys Array of historical APYs
     * @return timestamps Array of corresponding timestamps
     */
    function getYieldHistory(
        string calldata _protocol,
        uint256 _limit
    ) 
        external 
        view 
        returns (
            uint256[] memory apys,
            uint256[] memory timestamps
        ) 
    {
        HistoricalYield[] memory history = yieldHistory[_protocol];
        uint256 length = history.length > _limit ? _limit : history.length;
        
        apys = new uint256[](length);
        timestamps = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 index = history.length - 1 - i; // Most recent first
            apys[i] = history[index].apy;
            timestamps[i] = history[index].timestamp;
        }
    }

    // Admin functions
    function addProtocol(string calldata _protocol, uint8 _riskScore) 
        external 
        onlyOwner 
    {
        _addProtocol(_protocol, _riskScore);
    }

    function deactivateProtocol(string calldata _protocol, string calldata _reason) 
        external 
        onlyOwner 
    {
        require(protocolYields[_protocol].active, "Protocol already inactive");
        
        protocolYields[_protocol].active = false;
        emit ProtocolDeactivated(_protocol, _reason);
    }

    function authorizeUpdater(address _updater, bool _authorized) 
        external 
        onlyOwner 
    {
        authorizedUpdaters[_updater] = _authorized;
        emit UpdaterAuthorized(_updater, _authorized);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Internal functions
    function _addProtocol(string memory _protocol, uint8 _riskScore) internal {
        require(bytes(_protocol).length > 0, "Empty protocol name");
        require(_riskScore >= 1 && _riskScore <= 10, "Invalid risk score");
        require(!protocolYields[_protocol].active, "Protocol already exists");

        protocolYields[_protocol] = YieldData({
            protocol: _protocol,
            apy: 0,
            tvl: 0,
            riskScore: _riskScore,
            timestamp: block.timestamp,
            active: true
        });

        supportedProtocols.push(_protocol);
        emit ProtocolAdded(_protocol, _riskScore);
    }

    function _isStaleData(uint256 _timestamp) internal view returns (bool) {
        return block.timestamp - _timestamp > MAX_STALENESS;
    }

    function _getActiveProtocolCount() internal view returns (uint256 count) {
        for (uint256 i = 0; i < supportedProtocols.length; i++) {
            if (protocolYields[supportedProtocols[i]].active) {
                count++;
            }
        }
    }

    // View functions
    function getSupportedProtocols() external view returns (string[] memory) {
        return supportedProtocols;
    }

    function getTotalManagedProtocols() external view returns (uint256) {
        return supportedProtocols.length;
    }

    function isDataFresh(string calldata _protocol) external view returns (bool) {
        return !_isStaleData(protocolYields[_protocol].timestamp);
    }
}
