// hardhat.config.js - Blockchain deployment configuration
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // Flare Mainnet
    flare: {
      url: "https://flare-api.flare.network/ext/bc/C/rpc",
      chainId: 14,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 25000000000 // 25 gwei
    },
    // Flare Testnet (Coston2)
    flareTestnet: {
      url: "https://coston2-api.flare.network/ext/bc/C/rpc",
      chainId: 114,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 25000000000
    },
    // Local development
    hardhat: {
      chainId: 31337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        count: 10
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  }
};

// ===== PACKAGE.JSON FILES =====

// Backend package.json
const backendPackage = {
  "name": "defi-autopilot-backend",
  "version": "1.0.0",
  "description": "AI-powered cross-chain yield optimization engine",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest",
    "deploy": "node scripts/deploy.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "ethers": "^5.7.2",
    "axios": "^1.5.0",
    "ws": "^8.13.0",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.9.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.6.2"
  },
  "keywords": ["defi", "ai", "blockchain", "yield-optimization", "xrpl", "flare"],
  "author": "DeFi Autopilot Team",
  "license": "MIT"
};

// Frontend package.json
const frontendPackage = {
  "name": "defi-autopilot-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "ethers": "^5.7.2",
    "web3": "^4.0.3",
    "@web3-react/core": "^8.2.0",
    "@web3-react/metamask": "^8.2.1",
    "axios": "^1.5.0",
    "recharts": "^2.7.2"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "devDependencies": {
    "react-scripts": "5.0.1"
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
};

// Smart Contract package.json
const contractsPackage = {
  "name": "defi-autopilot-contracts",
  "version": "1.0.0",
  "description": "Smart contracts for DeFi Autopilot",
  "scripts": {
    "compile": "npx hardhat compile",
    "test": "npx hardhat test",
    "deploy:testnet": "npx hardhat run scripts/deploy.js --network flareTestnet",
    "deploy:mainnet": "npx hardhat run scripts/deploy.js --network flare",
    "verify": "npx hardhat verify",
    "flatten": "npx hardhat flatten"
  },
  "devDependencies": {
    "@nomiclabs/hardhat-ethers": "^2.2.3",
    "@nomiclabs/hardhat-waffle": "^2.0.6",
    "hardhat": "^2.17.1",
    "ethereum-waffle": "^4.0.10",
    "chai": "^4.3.8",
    "ethers": "^5.7.2",
    "dotenv": "^16.3.1"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.3",
    "@chainlink/contracts": "^0.6.1"
  },
  "keywords": ["ethereum", "solidity", "defi", "smart-contracts", "flare"],
  "license": "MIT"
};

// ===== DEPLOYMENT SCRIPTS =====

// scripts/deploy.js
const deployScript = `
const hre = require("hardhat");
const fs = require('fs');

async function main() {
    console.log("🚀 Deploying DeFi Autopilot contracts to", hre.network.name);
    console.log("==========================================");
    
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    console.log("Account balance:", hre.ethers.utils.formatEther(await deployer.getBalance()), "ETH");
    
    // Deploy YieldOracle
    console.log("\n📊 Deploying YieldOracle...");
    const YieldOracle = await hre.ethers.getContractFactory("YieldOracle");
    const yieldOracle = await YieldOracle.deploy();
    await yieldOracle.deployed();
    console.log("✅ YieldOracle deployed to:", yieldOracle.address);
    
    // Deploy PortfolioManager
    console.log("\n💼 Deploying PortfolioManager...");
    const PortfolioManager = await hre.ethers.getContractFactory("PortfolioManager");
    const portfolioManager = await PortfolioManager.deploy();
    await portfolioManager.deployed();
    console.log("✅ PortfolioManager deployed to:", portfolioManager.address);
    
    // Deploy RebalancingEngine
    console.log("\n⚖️ Deploying RebalancingEngine...");
    const RebalancingEngine = await hre.ethers.getContractFactory("RebalancingEngine");
    const rebalancingEngine = await RebalancingEngine.deploy(
        portfolioManager.address,
        yieldOracle.address
    );
    await rebalancingEngine.deployed();
    console.log("✅ RebalancingEngine deployed to:", rebalancingEngine.address);
    
    // Configure contracts
    console.log("\n🔧 Configuring contracts...");
    
    // Authorize rebalancing engine
    await portfolioManager.authorizeRebalancer(rebalancingEngine.address, true);
    console.log("✅ RebalancingEngine authorized");
    
    // Set up yield oracle updater
    await yieldOracle.authorizeUpdater(deployer.address, true);
    console.log("✅ Oracle updater authorized");
    
    // Save deployment info
    const deploymentInfo = {
        network: hre.network.name,
        chainId: hre.network.config.chainId,
        deployer: deployer.address,
        contracts: {
            YieldOracle: yieldOracle.address,
            PortfolioManager: portfolioManager.address,
            RebalancingEngine: rebalancingEngine.address
        },
        timestamp: new Date().toISOString(),
        blockNumber: await hre.ethers.provider.getBlockNumber()
    };
    
    fs.writeFileSync(
        \`deployments/\${hre.network.name}.json\`,
        JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log("\n🎉 Deployment completed successfully!");
    console.log("==========================================");
    console.log("📋 Contract Addresses:");
    console.log("YieldOracle:      ", yieldOracle.address);
    console.log("PortfolioManager: ", portfolioManager.address);
    console.log("RebalancingEngine:", rebalancingEngine.address);
    console.log("\\n💾 Deployment info saved to:", \`deployments/\${hre.network.name}.json\`);
    
    // Verification instructions
    if (hre.network.name !== 'hardhat' && hre.network.name !== 'localhost') {
        console.log("\\n🔍 To verify contracts, run:");
        console.log(\`npx hardhat verify \${yieldOracle.address} --network \${hre.network.name}\`);
        console.log(\`npx hardhat verify \${portfolioManager.address} --network \${hre.network.name}\`);
        console.log(\`npx hardhat verify \${rebalancingEngine.address} \${portfolioManager.address} \${yieldOracle.address} --network \${hre.network.name}\`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
`;

// ===== ENVIRONMENT CONFIGURATION =====

const envTemplate = `
# Blockchain Configuration
PRIVATE_KEY=your_private_key_here
FLARE_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc
XRPL_ENDPOINT=wss://s.altnet.rippletest.net:51233

# Contract Addresses (update after deployment)
PORTFOLIO_MANAGER_ADDRESS=
YIELD_ORACLE_ADDRESS=
REBALANCING_ENGINE_ADDRESS=

# API Configuration
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000

# External API Keys (optional - fallback to mock data)
AAVE_API_KEY=
COMPOUND_API_KEY=
CURVE_API_KEY=
YEARN_API_KEY=

# Security
JWT_SECRET=your_jwt_secret_here
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# Database (optional for advanced features)
DATABASE_URL=postgresql://localhost:5432/defi_autopilot

# Monitoring & Analytics
SENTRY_DSN=
ANALYTICS_KEY=
`;

// ===== PROJECT STRUCTURE SETUP =====

const projectStructure = `
defi-autopilot/
├── contracts/
│   ├── PortfolioManager.sol
│   ├── YieldOracle.sol
│   ├── RebalancingEngine.sol
│   └── interfaces/
├── backend/
│   ├── server.js
│   ├── ai/
│   │   ├── OptimizationEngine.js
│   │   ├── YieldAnalyzer.js
│   │   └── RouteOptimizer.js
│   └── xrpl/
│       └── SettlementEngine.js
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   └── Dashboard.js
│   │   ├── hooks/
│   │   ├── utils/
│   │   └── App.js
│   └── package.json
├── scripts/
│   ├── deploy.js
│   └── setup.js
├── test/
├── deployments/
├── .env
├── hardhat.config.js
└── README.md
`;

// ===== SETUP SCRIPT =====

const setupScript = `
#!/bin/bash

echo "🚀 Setting up DeFi Autopilot project..."

# Create directory structure
mkdir -p contracts backend frontend/src/components scripts test deployments

# Install contract dependencies
echo "📦 Installing smart contract dependencies..."
npm init -y
npm install --save-dev hardhat @nomiclabs/hardhat-ethers @nomiclabs/hardhat-waffle ethereum-waffle chai ethers dotenv
npm install @openzeppelin/contracts @chainlink/contracts

# Initialize Hardhat
npx hardhat

# Setup backend
echo "🔧 Setting up backend..."
cd backend
npm init -y
npm install express cors dotenv ethers axios ws helmet express-rate-limit
npm install --save-dev nodemon jest
cd ..

# Setup frontend
echo "🎨 Setting up frontend..."
cd frontend
npx create-react-app . --template typescript
npm install ethers @web3-react/core @web3-react/metamask axios recharts
cd ..

# Create .env file
echo "📝 Creating environment configuration..."
cat > .env << 'EOF'
${envTemplate}
EOF

echo "✅ Setup complete!"
echo "Next steps:"
echo "1. Add your private key to .env"
echo "2. Get Flare testnet tokens from faucet"
echo "3. Run 'npm run compile' to compile contracts"
echo "4. Run 'npm run deploy:testnet' to deploy"
echo "5. Start backend: 'cd backend && npm run dev'"
echo "6. Start frontend: 'cd frontend && npm start'"
`;

console.log("=".repeat(80));
console.log("📁 PROJECT STRUCTURE");
console.log("=".repeat(80));
console.log(projectStructure);

console.log("\n" + "=".repeat(80));
console.log("📦 BACKEND PACKAGE.JSON");  
console.log("=".repeat(80));
console.log(JSON.stringify(backendPackage, null, 2));

console.log("\n" + "=".repeat(80));
console.log("🎨 FRONTEND PACKAGE.JSON");
console.log("=".repeat(80));
console.log(JSON.stringify(frontendPackage, null, 2));

console.log("\n" + "=".repeat(80));
console.log("⛓️ CONTRACTS PACKAGE.JSON");
console.log("=".repeat(80));
console.log(JSON.stringify(contractsPackage, null, 2));

console.log("\n" + "=".repeat(80));
console.log("🚀 DEPLOYMENT SCRIPT");
console.log("=".repeat(80));
console.log(deployScript);

console.log("\n" + "=".repeat(80));
console.log("🔧 ENVIRONMENT TEMPLATE");
console.log("=".repeat(80));
console.log(envTemplate);

console.log("\n" + "=".repeat(80));
console.log("⚡ SETUP SCRIPT");
console.log("=".repeat(80));
console.log(setupScript);