// DeFi Autopilot AI Optimization Engine
// Node.js Backend for cross-chain yield optimization

const express = require('express');
const axios = require('axios');
const { ethers } = require('ethers');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();



// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Contract ABIs and addresses
const CONTRACT_ADDRESSES = {
  portfolioManager: process.env.PORTFOLIO_MANAGER_ADDRESS,
  yieldOracle: process.env.YIELD_ORACLE_ADDRESS,
  rebalancingEngine: process.env.REBALANCING_ENGINE_ADDRESS
};

// Initialize blockchain connection
const provider = new ethers.providers.JsonRpcProvider(process.env.FLARE_RPC_URL || 'https://coston2-api.flare.network/ext/bc/C/rpc');

// Initialize wallet only if private key is available
let wallet = null;
if (process.env.PRIVATE_KEY) {
  try {
    wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    console.log('✅ Wallet initialized:', wallet.address);
  } catch (error) {
    console.warn('⚠️  Wallet initialization failed, running in demo mode');
    wallet = null;
  }
} else {
  console.log('ℹ️  No private key provided, running in demo mode');
}

/**
 * AI Yield Analyzer - Monitors DeFi protocols for yield opportunities
 */
class YieldAnalyzer {
  constructor() {
    this.protocols = {
      'Aave': {
        endpoint: 'https://api.aave.com/data/liquidity/v2',
        parser: this.parseAaveData.bind(this),
        riskScore: 2
      },
      'Compound': {
        endpoint: 'https://api.compound.finance/api/v2/ctoken',
        parser: this.parseCompoundData.bind(this),
        riskScore: 2
      },
      'Curve': {
        endpoint: 'https://api.curve.fi/api/getPools/ethereum/main',
        parser: this.parseCurveData.bind(this),
        riskScore: 3
      },
      'Yearn': {
        endpoint: 'https://api.yearn.finance/v1/chains/1/vaults/all',
        parser: this.parseYearnData.bind(this),
        riskScore: 3
      },
      'Uniswap': {
        endpoint: 'https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3',
        parser: this.parseUniswapData.bind(this),
        riskScore: 4
      }
    };

    this.yieldCache = new Map();
    this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
  }

  /**
   * Fetch yield data from all supported protocols
   */
  async fetchAllYields() {
    const yields = {};
    const fetchPromises = [];

    for (const [protocolName, config] of Object.entries(this.protocols)) {
      fetchPromises.push(
        this.fetchProtocolYield(protocolName, config)
          .then(data => yields[protocolName] = data)
          .catch(error => {
            console.error(`Error fetching ${protocolName}:`, error.message);
            yields[protocolName] = this.getMockYieldData(protocolName);
          })
      );
    }

    await Promise.all(fetchPromises);
    return yields;
  }

  /**
   * Fetch yield data for a specific protocol
   */
  async fetchProtocolYield(protocolName, config) {
    const cacheKey = `yield_${protocolName}`;
    const cached = this.yieldCache.get(cacheKey);

    if (cached && (Date.now() - cached.timestamp < this.cacheTimeout)) {
      return cached.data;
    }

    try {
      const response = await axios.get(config.endpoint, {
        timeout: 10000,
        headers: { 'User-Agent': 'DeFi-Autopilot/1.0' }
      });

      const yieldData = config.parser(response.data);
      yieldData.riskScore = config.riskScore;
      yieldData.protocol = protocolName;
      yieldData.timestamp = Date.now();

      // Cache the result
      this.yieldCache.set(cacheKey, { data: yieldData, timestamp: Date.now() });

      return yieldData;
    } catch (error) {
      console.warn(`Failed to fetch real data for ${protocolName}, using mock data`);
      return this.getMockYieldData(protocolName);
    }
  }

  /**
   * Parse Aave protocol data
   */
  parseAaveData(data) {
    const reserves = data.reserves || [];
    const usdcReserve = reserves.find(r => r.symbol === 'USDC') || reserves[0];

    return {
      apy: parseFloat(usdcReserve?.liquidityRate || '320') / 100, // Convert to percentage
      tvl: parseFloat(usdcReserve?.totalLiquidity || '2500000000'),
      utilizationRate: parseFloat(usdcReserve?.utilizationRate || '0.75'),
      lastUpdated: Date.now()
    };
  }

  /**
   * Parse Compound protocol data
   */
  parseCompoundData(data) {
    const cTokens = data.cToken || [];
    const cUSDC = cTokens.find(t => t.underlying_symbol === 'USDC') || cTokens[0];

    return {
      apy: parseFloat(cUSDC?.supply_rate?.value || '780') / 1e16, // Convert from rate to percentage
      tvl: parseFloat(cUSDC?.total_supply?.value || '1800000000'),
      utilizationRate: parseFloat(cUSDC?.utilization?.value || '0.68'),
      lastUpdated: Date.now()
    };
  }

  /**
   * Parse Curve protocol data
   */
  parseCurveData(data) {
    const pools = data.data?.poolData || [];
    const stablePool = pools.find(p => p.coins?.includes('USDC')) || pools[0];

    return {
      apy: parseFloat(stablePool?.apy || '540') / 100,
      tvl: parseFloat(stablePool?.usdTotal || '850000000'),
      utilizationRate: 0.85,
      lastUpdated: Date.now()
    };
  }

  /**
   * Parse Yearn protocol data
   */
  parseYearnData(data) {
    const vaults = Array.isArray(data) ? data : [];
    const usdcVault = vaults.find(v => v.token?.symbol === 'USDC') || vaults[0];

    return {
      apy: parseFloat(usdcVault?.apy?.net_apy || '0.064') * 100,
      tvl: parseFloat(usdcVault?.tvl?.tvl || '650000000'),
      utilizationRate: 0.92,
      lastUpdated: Date.now()
    };
  }

  /**
   * Parse Uniswap protocol data
   */
  parseUniswapData(data) {
    return {
      apy: 4.2, // Mock data for Uniswap V3 USDC/ETH pool
      tvl: 420000000,
      utilizationRate: 0.65,
      lastUpdated: Date.now()
    };
  }

  /**
   * Generate mock yield data for demo purposes
   */
  getMockYieldData(protocolName) {
    const mockData = {
      'Aave': { apy: 3.2, tvl: 2500000000, riskScore: 2 },
      'Compound': { apy: 7.8, tvl: 1800000000, riskScore: 2 },
      'Curve': { apy: 5.4, tvl: 850000000, riskScore: 3 },
      'Yearn': { apy: 6.4, tvl: 650000000, riskScore: 3 },
      'Uniswap': { apy: 4.2, tvl: 420000000, riskScore: 4 }
    };

    return {
      ...mockData[protocolName],
      protocol: protocolName,
      utilizationRate: 0.75,
      lastUpdated: Date.now(),
      mock: true
    };
  }
}

/**
 * Cross-Chain Route Optimizer - Calculates optimal transaction paths
 */
class RouteOptimizer {
  constructor() {
    this.chainData = {
      'Flare': { gasPrice: 25, blockTime: 1.83, bridgeCost: 0 },
      'XRPL': { gasPrice: 0.00001, blockTime: 3.5, bridgeCost: 0.002 },
      'Ethereum': { gasPrice: 35, blockTime: 12, bridgeCost: 0.015 },
      'Polygon': { gasPrice: 1.2, blockTime: 2.1, bridgeCost: 0.008 },
      'Arbitrum': { gasPrice: 0.8, blockTime: 0.25, bridgeCost: 0.012 }
    };
  }

  /**
   * Calculate the most cost-effective route for cross-chain transactions
   */
  calculateOptimalRoute(fromChain, toChain, amount, urgency = 'normal') {
    const routes = [
      {
        path: [fromChain, 'XRPL', toChain],
        cost: this.chainData.XRPL.bridgeCost + this.chainData[toChain].bridgeCost,
        time: this.chainData.XRPL.blockTime + this.chainData[toChain].blockTime,
        slippage: 0.1
      },
      {
        path: [fromChain, 'Ethereum', toChain],
        cost: this.chainData.Ethereum.bridgeCost + this.chainData[toChain].bridgeCost,
        time: this.chainData.Ethereum.blockTime + this.chainData[toChain].blockTime,
        slippage: 0.3
      }
    ];

    // For same chain, no routing needed
    if (fromChain === toChain) {
      return {
        path: [fromChain],
        cost: this.chainData[fromChain].gasPrice * 0.0001, // Base transaction cost
        time: this.chainData[fromChain].blockTime,
        slippage: 0
      };
    }

    // Sort routes by cost (or time if urgent)
    const sortKey = urgency === 'urgent' ? 'time' : 'cost';
    return routes.sort((a, b) => a[sortKey] - b[sortKey])[0];
  }

  /**
   * Determine if rebalancing is profitable after routing costs
   */
  shouldRebalance(currentYield, newYield, portfolioValue, routeCost) {
    const annualYieldIncrease = (newYield - currentYield) / 100;
    const annualProfitIncrease = annualYieldIncrease * portfolioValue;
    const profitThreshold = routeCost * 1.15; // 15% minimum profit margin

    return annualProfitIncrease > profitThreshold;
  }
}

/**
 * Main AI Optimization Engine
 */
class OptimizationEngine {
  constructor() {
    this.yieldAnalyzer = new YieldAnalyzer();
    this.routeOptimizer = new RouteOptimizer();
    this.riskProfiles = {
      1: { maxRisk: 3, minYieldDiff: 50 }, // Conservative: 0.5% min diff
      2: { maxRisk: 5, minYieldDiff: 30 }, // Balanced: 0.3% min diff
      3: { maxRisk: 8, minYieldDiff: 10 }  // Aggressive: 0.1% min diff
    };
  }

  /**
   * Generate optimization strategy for a portfolio
   */
  async generateOptimizationStrategy(portfolio) {
    const yields = await this.yieldAnalyzer.fetchAllYields();
    const currentProtocol = portfolio.protocol || portfolio.currentProtocol || 'Aave';
    const currentYield = portfolio.currentYield || 3.2;
    const riskProfile = portfolio.riskProfile || 2;
    const totalValue = portfolio.totalValue || portfolio.balance * 1000; // Convert ETH to USD estimate

    const strategy = {
      shouldRebalance: false,
      recommendation: null,
      alternatives: [],
      riskAssessment: 'LOW',
      executionTime: Date.now()
    };

    // Find best opportunities within risk tolerance
    const profile = this.riskProfiles[riskProfile];
    const opportunities = this.identifyOpportunities(yields, currentYield, profile);

    if (opportunities.length === 0) {
      return strategy;
    }

    // Calculate optimal route for the best opportunity
    const bestOpportunity = opportunities[0];
    const route = this.routeOptimizer.calculateOptimalRoute(
      'Flare',
      'Flare', // Same chain for demo
      totalValue
    );

    // Check if profitable after routing costs
    if (this.routeOptimizer.shouldRebalance(
      currentYield,
      bestOpportunity.apy,
      totalValue,
      route.cost * 1000 // Convert to USD
    )) {
      const yieldIncrease = bestOpportunity.apy - currentYield;
      const annualProfit = (yieldIncrease / 100) * totalValue;
      const executionCost = route.cost * 1000;

      strategy.shouldRebalance = true;
      strategy.recommendation = {
        fromProtocol: currentProtocol,
        toProtocol: bestOpportunity.protocol,
        currentYield: currentYield,
        newYield: bestOpportunity.apy,
        yieldIncrease: yieldIncrease,
        annualProfit: Math.round(annualProfit),
        executionCost: Math.round(executionCost),
        netProfit: Math.round(annualProfit - executionCost),
        paybackPeriod: Math.round((executionCost / annualProfit) * 365),
        route: {
          path: route.path,
          totalCost: route.cost,
          estimatedTime: Math.round(route.time)
        }
      };

      strategy.riskAssessment = this.assessRisk(bestOpportunity.riskScore, yieldIncrease);
    }

    // Add alternative options
    strategy.alternatives = opportunities.slice(1, 3).map(opp => ({
      protocol: opp.protocol,
      apy: opp.apy,
      riskScore: opp.riskScore,
      yieldIncrease: opp.apy - currentYield
    }));

    return strategy;
  }

  /**
   * Identify yield opportunities within risk tolerance
   */
  identifyOpportunities(yields, currentYield, profile) {
    const opportunities = [];

    for (const [protocol, data] of Object.entries(yields)) {
      if (
        data.riskScore <= profile.maxRisk &&
        data.apy > currentYield &&
        (data.apy - currentYield) * 100 >= profile.minYieldDiff && // Convert to basis points
        data.tvl >= 100000000 // Minimum $100M TVL
      ) {
        opportunities.push({
          protocol,
          apy: data.apy,
          riskScore: data.riskScore,
          tvl: data.tvl,
          yieldIncrease: data.apy - currentYield
        });
      }
    }

    // Sort by risk-adjusted yield (higher yield / lower risk = better)
    return opportunities.sort((a, b) => {
      const scoreA = a.yieldIncrease / (a.riskScore + 1);
      const scoreB = b.yieldIncrease / (b.riskScore + 1);
      return scoreB - scoreA;
    });
  }

  /**
   * Assess risk level of the optimization
   */
  assessRisk(riskScore, yieldIncrease) {
    if (riskScore <= 2 && yieldIncrease <= 2) return 'LOW';
    if (riskScore <= 4 && yieldIncrease <= 5) return 'MEDIUM';
    return 'HIGH';
  }
}

// Initialize AI engine
const optimizationEngine = new OptimizationEngine();

// API Routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.get('/api/yields', async (req, res) => {
  try {
    const yields = await optimizationEngine.yieldAnalyzer.fetchAllYields();
    res.json({
      success: true,
      data: yields,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error fetching yields:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch yield data',
      message: error.message
    });
  }
});

app.post('/api/optimize', async (req, res) => {
  try {
    const portfolio = req.body;

    if (!portfolio || !portfolio.totalValue) {
      return res.status(400).json({
        success: false,
        error: 'Invalid portfolio data'
      });
    }

    const strategy = await optimizationEngine.generateOptimizationStrategy(portfolio);

    res.json({
      success: true,
      strategy,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error generating optimization:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to generate optimization strategy',
      message: error.message
    });
  }
});

app.post('/api/route', (req, res) => {
  try {
    const { fromChain, toChain, amount, urgency } = req.body;

    if (!fromChain || !toChain || !amount) {
      return res.status(400).json({
        success: false,
        error: 'Missing required parameters'
      });
    }

    const route = optimizationEngine.routeOptimizer.calculateOptimalRoute(
      fromChain,
      toChain,
      amount,
      urgency
    );

    res.json({
      success: true,
      route,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error calculating route:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to calculate optimal route',
      message: error.message
    });
  }
});

// Risk assessment endpoint
app.post('/api/risk-assessment', async (req, res) => {
  try {
    const { protocol, amount, riskProfile } = req.body;

    const yields = await optimizationEngine.yieldAnalyzer.fetchAllYields();
    const protocolData = yields[protocol];

    if (!protocolData) {
      return res.status(404).json({
        success: false,
        error: 'Protocol not found'
      });
    }

    const assessment = {
      protocol,
      riskScore: protocolData.riskScore,
      riskLevel: optimizationEngine.assessRisk(protocolData.riskScore, protocolData.apy),
      tvl: protocolData.tvl,
      recommendation: protocolData.riskScore <= optimizationEngine.riskProfiles[riskProfile].maxRisk ? 'APPROVED' : 'REJECTED',
      factors: {
        protocolMaturity: protocolData.riskScore <= 3 ? 'HIGH' : 'MEDIUM',
        liquidityDepth: protocolData.tvl >= 1000000000 ? 'HIGH' : 'MEDIUM',
        yieldStability: 'MEDIUM' // Would be calculated from historical data
      }
    };

    res.json({
      success: true,
      assessment,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error in risk assessment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to assess risk',
      message: error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`🚀 DeFi Autopilot backend running on port ${PORT}`);
  console.log(`📊 API endpoints available at http://localhost:${PORT}/api/`);
  console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
