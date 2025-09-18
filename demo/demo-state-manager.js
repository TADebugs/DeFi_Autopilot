// Demo State Manager - Manages the 30-second demo flow
class DemoStateManager {
  constructor() {
    this.currentStep = 0;
    this.demoSteps = [
      {
        step: 1,
        title: "Portfolio Display",
        duration: 5000, // 5 seconds
        data: {
          portfolioValue: 10000,
          currentYield: 3.2,
          protocol: "Aave",
          annualEarnings: 320
        }
      },
      {
        step: 2,
        title: "AI Discovery",
        duration: 8000, // 8 seconds
        data: {
          aiDetection: true,
          newOpportunity: {
            protocol: "Compound",
            yield: 7.8,
            improvement: 4.6,
            annualProfit: 460
          }
        }
      },
      {
        step: 3,
        title: "Cost Analysis",
        duration: 7000, // 7 seconds
        data: {
          analysis: {
            traditionalCost: 50,
            xrplCost: 3,
            netProfit: 457,
            profitMargin: "15.3x"
          }
        }
      },
      {
        step: 4,
        title: "Execution",
        duration: 8000, // 8 seconds
        data: {
          execution: {
            route: ["Flare", "XRPL", "Flare"],
            progress: 0,
            estimatedTime: 8,
            status: "executing"
          }
        }
      },
      {
        step: 5,
        title: "Results",
        duration: 2000, // 2 seconds
        data: {
          finalState: {
            portfolioValue: 10000,
            newYield: 7.8,
            protocol: "Compound",
            profit: 457,
            success: true
          }
        }
      }
    ];

    this.totalDuration = this.demoSteps.reduce((sum, step) => sum + step.duration, 0);
  }

  getCurrentStep() {
    return this.demoSteps[this.currentStep] || this.demoSteps[0];
  }

  nextStep() {
    if (this.currentStep < this.demoSteps.length - 1) {
      this.currentStep++;
    }
    return this.getCurrentStep();
  }

  resetDemo() {
    this.currentStep = 0;
    return this.getCurrentStep();
  }

  getDemoData() {
    return {
      currentStep: this.currentStep + 1,
      totalSteps: this.demoSteps.length,
      stepData: this.getCurrentStep(),
      progress: ((this.currentStep + 1) / this.demoSteps.length) * 100,
      totalDuration: this.totalDuration
    };
  }

  // Simulate the complete 30-second flow
  async runFullDemo(callback) {
    this.resetDemo();

    for (let i = 0; i < this.demoSteps.length; i++) {
      const step = this.demoSteps[i];

      // Call callback with current step data
      if (callback) {
        callback(this.getDemoData());
      }

      // Wait for step duration
      await new Promise(resolve => setTimeout(resolve, step.duration));

      // Move to next step
      if (i < this.demoSteps.length - 1) {
        this.nextStep();
      }
    }

    return this.getDemoData();
  }
}

// Mock DeFi Protocol Data
const DEMO_PROTOCOLS = {
  "Aave": {
    apy: 3.2,
    tvl: 2500000000,
    riskScore: 2,
    utilizationRate: 0.75,
    category: "Lending",
    logo: "🏦"
  },
  "Compound": {
    apy: 7.8,
    tvl: 1800000000,
    riskScore: 2,
    utilizationRate: 0.68,
    category: "Lending",
    logo: "🏛️"
  },
  "Curve": {
    apy: 5.4,
    tvl: 850000000,
    riskScore: 3,
    utilizationRate: 0.85,
    category: "DEX",
    logo: "🌊"
  },
  "Yearn": {
    apy: 6.4,
    tvl: 650000000,
    riskScore: 3,
    utilizationRate: 0.92,
    category: "Yield Farming",
    logo: "🚜"
  },
  "Uniswap": {
    apy: 4.2,
    tvl: 420000000,
    riskScore: 4,
    utilizationRate: 0.65,
    category: "DEX",
    logo: "🦄"
  }
};

// Demo Portfolio Data
const DEMO_PORTFOLIO = {
  address: "0x21e9E8666A66E0E6ff615d6Ee39Cc86Ee1F1DE5f",
  totalValue: 10000,
  currentYield: 3.2,
  protocol: "Aave",
  riskProfile: 2, // Balanced
  autoRebalanceEnabled: true,
  lastRebalance: Date.now() - (24 * 60 * 60 * 1000), // 24 hours ago
  totalProfit: 0,
  history: [
    {
      date: Date.now() - (7 * 24 * 60 * 60 * 1000),
      action: "deposit",
      amount: 10000,
      protocol: "Aave"
    }
  ]
};

// Export for use in backend
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    DemoStateManager,
    DEMO_PROTOCOLS,
    DEMO_PORTFOLIO
  };
}

// Export for frontend use
if (typeof window !== 'undefined') {
  window.DemoStateManager = DemoStateManager;
  window.DEMO_PROTOCOLS = DEMO_PROTOCOLS;
  window.DEMO_PORTFOLIO = DEMO_PORTFOLIO;
}
