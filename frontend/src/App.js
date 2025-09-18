// DeFi Autopilot - React Dashboard
import React, { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import './App.css';

const App = () => {
  // State management
  const [portfolio, setPortfolio] = useState(null);
  const [yields, setYields] = useState({});
  const [optimizationSuggestion, setSuggestion] = useState(null);
  const [loading, setLoading] = useState(true);
  const [connected, setConnected] = useState(false);
  const [rebalancing, setRebalancing] = useState(false);
  const [account, setAccount] = useState('');

  // API base URL
  const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:3001';

  // Initialize dashboard
  useEffect(() => {
    initializeApp();

    // Set up real-time updates
    const interval = setInterval(() => {
      if (connected && portfolio) {
        fetchYields();
        checkOptimization();
      }
    }, 30000);

    return () => {
      clearInterval(interval);
    };
  }, [connected, portfolio]);

  const initializeApp = async () => {
    try {
      await connectWallet();
      await fetchYields();
      setLoading(false);
    } catch (error) {
      console.error('Initialization error:', error);
      setLoading(false);
    }
  };

  const connectWallet = async () => {
    try {
      if (typeof window.ethereum === 'undefined') {
        alert('Please install MetaMask to use DeFi Autopilot');
        return;
      }

      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("eth_requestAccounts", []);
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      const balance = await signer.getBalance();

      setAccount(address);
      setConnected(true);
      
      setPortfolio({
        address,
        balance: parseFloat(ethers.utils.formatEther(balance)),
        currentYield: 3.2,
        protocol: 'Aave',
        riskProfile: 2,
        totalValue: 10000, // Mock for demo
        autoRebalanceEnabled: true
      });

      // Check for optimization after connecting
      setTimeout(checkOptimization, 2000);
      
    } catch (error) {
      console.error('Wallet connection failed:', error);
      alert('Failed to connect wallet: ' + error.message);
    }
  };

  const fetchYields = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE}/api/yields`);
      const data = await response.json();
      
      if (data.success) {
        setYields(data.data);
      } else {
        // Use fallback data for demo
        setYields({
          'Aave': { apy: 3.2, tvl: 2500000000, riskScore: 2, protocol: 'Aave' },
          'Compound': { apy: 7.8, tvl: 1800000000, riskScore: 2, protocol: 'Compound' },
          'Curve': { apy: 5.4, tvl: 850000000, riskScore: 3, protocol: 'Curve' },
          'Yearn': { apy: 6.4, tvl: 650000000, riskScore: 3, protocol: 'Yearn' },
          'Uniswap': { apy: 4.2, tvl: 420000000, riskScore: 4, protocol: 'Uniswap' }
        });
      }
    } catch (error) {
      console.error('Error fetching yields:', error);
      // Fallback yields for demo
      setYields({
        'Aave': { apy: 3.2, tvl: 2500000000, riskScore: 2 },
        'Compound': { apy: 7.8, tvl: 1800000000, riskScore: 2 },
        'Curve': { apy: 5.4, tvl: 850000000, riskScore: 3 },
        'Yearn': { apy: 6.4, tvl: 650000000, riskScore: 3 }
      });
    }
  }, [API_BASE]);

  const checkOptimization = useCallback(async () => {
    if (!portfolio) return;

    try {
      const response = await fetch(`${API_BASE}/api/optimize`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(portfolio)
      });
      
      const data = await response.json();
      
      if (data.success && data.strategy.shouldRebalance) {
        setSuggestion(data.strategy.recommendation);
      } else {
        // Demo suggestion for hackathon
        setSuggestion({
          fromProtocol: 'Aave',
          toProtocol: 'Compound',
          currentYield: 3.2,
          newYield: 7.8,
          yieldIncrease: 4.6,
          annualProfit: 460,
          executionCost: 3,
          netProfit: 457,
          paybackPeriod: 2,
          route: {
            path: ['Flare', 'XRPL', 'Flare'],
            totalCost: 0.002,
            estimatedTime: 8
          }
        });
      }
    } catch (error) {
      console.error('Optimization check failed:', error);
    }
  }, [portfolio, API_BASE]);

  const executeRebalance = async () => {
    if (!optimizationSuggestion) return;
    
    setRebalancing(true);
    
    try {
      // Simulate the rebalancing process
      await new Promise(resolve => {
        let progress = 0;
        const interval = setInterval(() => {
          progress += 12.5; // 8 steps over 8 seconds
          
          if (progress >= 100) {
            clearInterval(interval);
            resolve();
          }
        }, 1000);
      });

      // Update portfolio state
      setPortfolio(prev => ({
        ...prev,
        currentYield: optimizationSuggestion.newYield,
        protocol: optimizationSuggestion.toProtocol
      }));

      setSuggestion(null);
      alert(`🎉 Portfolio successfully rebalanced! Now earning ${optimizationSuggestion.newYield}% APY on ${optimizationSuggestion.toProtocol}`);
      
    } catch (error) {
      alert('Rebalancing failed: ' + error.message);
    }
    
    setRebalancing(false);
  };

  // Loading screen
  if (loading) {
    return (
      <div className="loading">
        <div className="loading-spinner"></div>
        <span>Loading DeFi Autopilot...</span>
      </div>
    );
  }

  // Connection screen
  if (!connected) {
    return (
      <div className="dashboard">
        <div className="header">
          <h1 className="title">🚀 DeFi Autopilot</h1>
          <p className="subtitle">AI-Powered Cross-Chain Yield Optimization</p>
          <button className="connect-button" onClick={connectWallet}>
            Connect Wallet
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard">
      <div className="header">
        <h1 className="title">🚀 DeFi Autopilot</h1>
        <p className="subtitle">AI-Powered Cross-Chain Yield Optimization</p>
        <div className="status-indicator">
          <div className="status-dot"></div>
          <span>Connected: {account.substring(0, 6)}...{account.substring(account.length - 4)}</span>
        </div>
      </div>

      <div className="container">
        {/* Portfolio Overview */}
        <div className="card">
          <h2 className="card-title">Your Portfolio</h2>
          <div className="balance">
            ${portfolio?.totalValue?.toLocaleString() || '10,000'}
          </div>
          <div className="yield">
            Current Yield: {portfolio?.currentYield}% APY
          </div>
          <div className="protocol">
            Protocol: {portfolio?.protocol}
          </div>
          <div className="status-indicator">
            <div className="status-dot"></div>
            <span>Auto-Rebalance: Enabled</span>
          </div>
        </div>

        {/* Live Yields */}
        <div className="card">
          <h2 className="card-title">Live Market Yields</h2>
          {Object.entries(yields).map(([protocol, data]) => (
            <div key={protocol} className="yield-row">
              <span className="protocol-name">{protocol}</span>
              <span className="yield-value">{data.apy}% APY</span>
            </div>
          ))}
        </div>

        {/* Optimization Alert */}
        {optimizationSuggestion && (
          <div className="optimization-alert">
            <h3 className="alert-title">
              🎯 Optimization Opportunity Detected!
            </h3>
            <p className="alert-description">
              AI found a better yield opportunity: Move from{' '}
              <strong>{optimizationSuggestion.fromProtocol}</strong> ({optimizationSuggestion.currentYield}%) to{' '}
              <strong>{optimizationSuggestion.toProtocol}</strong> ({optimizationSuggestion.newYield}%)
            </p>
            
            <div className="profit-grid">
              <div className="profit-item">
                <div className="profit-label">Annual Profit</div>
                <div className="profit-value">
                  +${optimizationSuggestion.annualProfit}
                </div>
              </div>
              <div className="profit-item">
                <div className="profit-label">Execution Cost</div>
                <div className="profit-value">
                  ${optimizationSuggestion.executionCost}
                </div>
              </div>
              <div className="profit-item">
                <div className="profit-label">Net Profit</div>
                <div className="profit-value">
                  +${optimizationSuggestion.netProfit}
                </div>
              </div>
              <div className="profit-item">
                <div className="profit-label">Execution Time</div>
                <div className="profit-value">
                  {optimizationSuggestion.route?.estimatedTime || 8}s
                </div>
              </div>
            </div>

            <button
              className={`rebalance-button ${rebalancing ? 'disabled' : ''}`}
              onClick={executeRebalance}
              disabled={rebalancing}
            >
              {rebalancing ? '⏳ Executing Rebalance...' : '🚀 Execute AI Rebalance'}
            </button>
          </div>
        )}

        {/* Portfolio Stats */}
        <div className="card">
          <h2 className="card-title">Portfolio Performance</h2>
          <div className="yield-row">
            <span>Total Assets</span>
            <span className="yield-value">
              ${portfolio?.totalValue?.toLocaleString() || '10,000'}
            </span>
          </div>
          <div className="yield-row">
            <span>Current APY</span>
            <span className="yield-value">{portfolio?.currentYield}%</span>
          </div>
          <div className="yield-row">
            <span>Risk Level</span>
            <span style={{ color: '#60a5fa' }}>
              {portfolio?.riskProfile === 1 ? 'Conservative' :
               portfolio?.riskProfile === 2 ? 'Balanced' : 'Aggressive'}
            </span>
          </div>
          <div className="yield-row">
            <span>Annual Earnings</span>
            <span className="yield-value">
              ${Math.round((portfolio?.totalValue || 10000) * (portfolio?.currentYield || 3.2) / 100).toLocaleString()}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
