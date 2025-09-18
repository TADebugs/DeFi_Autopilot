#!/bin/bash

# DeFi Autopilot - Flare Development Setup Script
# Sets up the complete development environment for Flare integration

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Setting up DeFi Autopilot for Flare development...${NC}"
echo "========================================================="

# Step 1: Install dependencies
echo -e "${BLUE}📦 Installing Hardhat and Flare dependencies...${NC}"
npm install --force

# Step 2: Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
    cat > .env << 'EOF'
# Flare Network Configuration
PRIVATE_KEY=your_private_key_here

# Network URLs
FLARE_RPC_URL=https://flare-api.flare.network/ext/bc/C/rpc
FLARE_TESTNET_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc
XRPL_TESTNET_URL=wss://s.altnet.rippletest.net:51233

# Contract Addresses (will be updated after deployment)
PORTFOLIO_MANAGER_ADDRESS=
YIELD_ORACLE_ADDRESS=
REBALANCING_ENGINE_ADDRESS=

# Backend Configuration
PORT=3001
NODE_ENV=development
DEMO_MODE=true

# Frontend Configuration
REACT_APP_API_URL=http://localhost:3001
REACT_APP_FLARE_CHAIN_ID=114
REACT_APP_FLARE_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc
EOF
    echo -e "${GREEN}✅ .env file created${NC}"
    echo -e "${YELLOW}⚠️  Please add your private key to .env file${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Step 3: Compile contracts
echo -e "${BLUE}🔨 Compiling smart contracts...${NC}"
if npx hardhat compile; then
    echo -e "${GREEN}✅ Smart contracts compiled successfully${NC}"
else
    echo -e "${RED}❌ Smart contract compilation failed${NC}"
    exit 1
fi

# Step 4: Run tests
echo -e "${BLUE}🧪 Running smart contract tests...${NC}"
if npx hardhat test; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed - check implementation${NC}"
fi

# Step 5: Setup backend
echo -e "${BLUE}🖥️  Setting up backend...${NC}"
cd backend
if [ -f package.json ]; then
    npm install
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${RED}❌ Backend package.json not found${NC}"
fi
cd ..

# Step 6: Setup frontend
echo -e "${BLUE}🎨 Setting up frontend...${NC}"
cd frontend
if [ -f package.json ]; then
    npm install
    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
else
    echo -e "${RED}❌ Frontend package.json not found${NC}"
fi
cd ..

# Step 7: Create demo data
echo -e "${BLUE}📊 Creating demo data...${NC}"
mkdir -p demo
cat > demo/demo-data.json << 'EOF'
{
  "portfolios": {
    "demo": {
      "address": "0x742d35Cc6634C0532925a3b8D35Cc6634C0532925",
      "totalValue": 10000,
      "currentYield": 3.2,
      "protocol": "Aave",
      "riskProfile": 2,
      "autoRebalanceEnabled": true
    }
  },
  "yields": {
    "Aave": { "apy": 3.2, "tvl": 2500000000, "riskScore": 2 },
    "Compound": { "apy": 7.8, "tvl": 1800000000, "riskScore": 2 },
    "Curve": { "apy": 5.4, "tvl": 850000000, "riskScore": 3 },
    "Yearn": { "apy": 6.4, "tvl": 650000000, "riskScore": 3 }
  },
  "optimization": {
    "fromProtocol": "Aave",
    "toProtocol": "Compound",
    "currentYield": 3.2,
    "newYield": 7.8,
    "annualProfit": 460,
    "executionCost": 3,
    "netProfit": 457,
    "executionTime": 8
  }
}
EOF

# Step 8: Create start scripts
echo -e "${BLUE}🚀 Creating development scripts...${NC}"

# Backend start script
cat > start-backend.sh << 'EOF'
#!/bin/bash
echo "🖥️  Starting DeFi Autopilot backend..."
cd backend && npm run dev
EOF

# Frontend start script  
cat > start-frontend.sh << 'EOF'
#!/bin/bash
echo "🎨 Starting DeFi Autopilot frontend..."
cd frontend && npm start
EOF

# Full development script
cat > start-dev.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting DeFi Autopilot full development environment..."

# Function to cleanup background processes
cleanup() {
    echo "Shutting down servers..."
    kill $(jobs -p) 2>/dev/null
    exit
}

trap cleanup INT TERM

# Start backend
echo "Starting backend server..."
cd backend && npm run dev &

# Wait for backend to start
sleep 3

# Start frontend
echo "Starting frontend server..."
cd frontend && npm start &

# Keep script running
echo "✅ Both servers started!"
echo "📊 Backend API: http://localhost:3001"
echo "🎨 Frontend: http://localhost:3000"
echo "Press Ctrl+C to stop all servers"

wait
EOF

chmod +x start-backend.sh start-frontend.sh start-dev.sh

# Step 9: Final checks
echo -e "${BLUE}🔍 Running final checks...${NC}"

# Check if we can connect to Flare testnet
if curl -s "https://coston2-api.flare.network/ext/bc/C/rpc" > /dev/null; then
    echo -e "${GREEN}✅ Flare testnet RPC accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Flare testnet RPC not accessible - check internet connection${NC}"
fi

# Check project structure
if [ -f "contracts/PortfolioManager.sol" ] && [ -f "backend/server.js" ] && [ -f "frontend/src/App.js" ]; then
    echo -e "${GREEN}✅ Project structure is complete${NC}"
else
    echo -e "${RED}❌ Missing critical project files${NC}"
fi

echo ""
echo -e "${GREEN}🎉 DeFi Autopilot development environment setup complete!${NC}"
echo "========================================================="
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Add your private key to .env file"
echo "2. Get Flare testnet tokens: https://coston2-faucet.flare.network/"
echo "3. Deploy contracts: npm run deploy:testnet"
echo "4. Start development: ./start-dev.sh"
echo ""
echo -e "${BLUE}🔗 Useful links:${NC}"
echo "• Flare docs: https://docs.flare.network/"
echo "• Coston2 explorer: https://coston2-explorer.flare.network/"
echo "• XRPL testnet: https://testnet.xrpl.org/"
echo ""
echo -e "${GREEN}🚀 Ready to build the future of DeFi!${NC}"
