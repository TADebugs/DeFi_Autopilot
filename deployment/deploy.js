const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
    console.log("🚀 Deploying DeFi Autopilot contracts to", hre.network.name);
    console.log("==========================================");
    
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    console.log("Account balance:", hre.ethers.utils.formatEther(await deployer.getBalance()), "ETH");
    
    // Create deployments directory if it doesn't exist
    const deploymentsDir = path.join(__dirname, '../deployments');
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir, { recursive: true });
    }
    
    try {
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
        console.log("Authorizing RebalancingEngine...");
        const authTx = await portfolioManager.authorizeRebalancer(rebalancingEngine.address, true);
        await authTx.wait();
        console.log("✅ RebalancingEngine authorized");
        
        // Set up yield oracle updater
        console.log("Authorizing Oracle updater...");
        const oracleAuthTx = await yieldOracle.authorizeUpdater(deployer.address, true);
        await oracleAuthTx.wait();
        console.log("✅ Oracle updater authorized");
        
        // Authorize AI engine (deployer for now)
        console.log("Authorizing AI engine...");
        const aiAuthTx = await rebalancingEngine.authorizeAIEngine(deployer.address, true);
        await aiAuthTx.wait();
        console.log("✅ AI engine authorized");
        
        // Initialize with some mock yield data for demo
        console.log("\n📈 Initializing with demo yield data...");
        const initYieldTx1 = await yieldOracle.updateYield("Aave", 320, hre.ethers.utils.parseEther("2500000000"), 2);
        await initYieldTx1.wait();
        
        const initYieldTx2 = await yieldOracle.updateYield("Compound", 780, hre.ethers.utils.parseEther("1800000000"), 2);
        await initYieldTx2.wait();
        
        const initYieldTx3 = await yieldOracle.updateYield("Curve", 540, hre.ethers.utils.parseEther("850000000"), 3);
        await initYieldTx3.wait();
        
        console.log("✅ Demo yield data initialized");
        
        // Save deployment info
        const deploymentInfo = {
            network: hre.network.name,
            chainId: hre.network.config.chainId,
            deployer: deployer.address,
            deployerBalance: hre.ethers.utils.formatEther(await deployer.getBalance()),
            contracts: {
                YieldOracle: {
                    address: yieldOracle.address,
                    deploymentHash: yieldOracle.deployTransaction.hash
                },
                PortfolioManager: {
                    address: portfolioManager.address,
                    deploymentHash: portfolioManager.deployTransaction.hash
                },
                RebalancingEngine: {
                    address: rebalancingEngine.address,
                    deploymentHash: rebalancingEngine.deployTransaction.hash
                }
            },
            timestamp: new Date().toISOString(),
            blockNumber: await hre.ethers.provider.getBlockNumber(),
            gasUsed: {
                YieldOracle: yieldOracle.deployTransaction.gasLimit.toString(),
                PortfolioManager: portfolioManager.deployTransaction.gasLimit.toString(),
                RebalancingEngine: rebalancingEngine.deployTransaction.gasLimit.toString()
            }
        };
        
        const deploymentFile = path.join(deploymentsDir, `${hre.network.name}.json`);
        fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
        
        // Create .env update file
        const envUpdates = `
# Contract addresses deployed on ${hre.network.name}
PORTFOLIO_MANAGER_ADDRESS=${portfolioManager.address}
YIELD_ORACLE_ADDRESS=${yieldOracle.address}
REBALANCING_ENGINE_ADDRESS=${rebalancingEngine.address}
`;
        
        const envFile = path.join(__dirname, '../.env.contracts');
        fs.writeFileSync(envFile, envUpdates);
        
        console.log("\n🎉 Deployment completed successfully!");
        console.log("==========================================");
        console.log("📋 Contract Addresses:");
        console.log("YieldOracle:      ", yieldOracle.address);
        console.log("PortfolioManager: ", portfolioManager.address);
        console.log("RebalancingEngine:", rebalancingEngine.address);
        console.log(`\n💾 Deployment info saved to: ${deploymentFile}`);
        console.log(`📝 Environment variables saved to: ${envFile}`);
        
        // Verification instructions
        if (hre.network.name !== 'hardhat' && hre.network.name !== 'localhost') {
            console.log("\n🔍 To verify contracts, run:");
            console.log(`npx hardhat verify ${yieldOracle.address} --network ${hre.network.name}`);
            console.log(`npx hardhat verify ${portfolioManager.address} --network ${hre.network.name}`);
            console.log(`npx hardhat verify ${rebalancingEngine.address} ${portfolioManager.address} ${yieldOracle.address} --network ${hre.network.name}`);
        }
        
        // Demo instructions
        console.log("\n🎯 Demo Setup Instructions:");
        console.log("1. Copy contract addresses to your .env file");
        console.log("2. Start the backend server: cd backend && npm run dev");
        console.log("3. Start the frontend: cd frontend && npm start");
        console.log("4. Connect MetaMask to Flare testnet");
        console.log("5. Create a portfolio and watch the AI optimization!");
        
    } catch (error) {
        console.error("❌ Deployment failed:", error);
        
        // Save error info
        const errorInfo = {
            network: hre.network.name,
            error: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString()
        };
        
        const errorFile = path.join(deploymentsDir, `${hre.network.name}_error.json`);
        fs.writeFileSync(errorFile, JSON.stringify(errorInfo, null, 2));
        
        throw error;
    }
}

// Handle script execution
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("💥 Script execution failed:", error);
        process.exit(1);
    });
