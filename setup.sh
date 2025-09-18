#!/bin/bash

# DeFi Autopilot Setup Script
# Automated setup for development environment

set -e  # Exit on any error

echo "🚀 Setting up DeFi Autopilot development environment..."
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

NODE_VERSION=$(node --version | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -lt 16 ]; then
    print_error "Node.js version 16+ required. Current version: $(node --version)"
    exit 1
fi

print_status "Node.js $(node --version) detected"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

print_status "npm $(npm --version) detected"

# Install root dependencies
print_info "Installing root dependencies..."
npm install --silent
print_status "Root dependencies installed"

# Setup backend
print_info "Setting up backend..."
cd backend

if [ ! -f package.json ]; then
    print_error "Backend package.json not found!"
    exit 1
fi

npm install --silent
print_status "Backend dependencies installed"

# Create backend .env if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << EOF
PORT=3001
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000

# Contract addresses (will be updated after deployment)
PORTFOLIO_MANAGER_ADDRESS=
YIELD_ORACLE_ADDRESS=
REBALANCING_ENGINE_ADDRESS=
EOF
    print_info "Created backend .env file"
fi

cd ..

# Setup frontend
print_info "Setting up frontend..."
cd frontend

# Create React app if src doesn't exist
if [ ! -d src ]; then
    print_info "Creating React application..."
    npx create-react-app . --template typescript --silent
fi

# Install additional dependencies
npm install --silent
print_status "Frontend dependencies installed"

# Create frontend .env if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << EOF
REACT_APP_API_URL=http://localhost:3001
REACT_APP_FLARE_CHAIN_ID=114
REACT_APP_FLARE_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc
EOF
    print_info "Created frontend .env file"
fi

cd ..

# Create main .env file if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << EOF
# Blockchain Configuration
PRIVATE_KEY=your_private_key_here
FLARE_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc
XRPL_TESTNET_URL=wss://s.altnet.rippletest.net:51233

# Contract Addresses (update after deployment)
PORTFOLIO_MANAGER_ADDRESS=
YIELD_ORACLE_ADDRESS=
REBALANCING_ENGINE_ADDRESS=

# Backend Configuration
PORT=3001
NODE_ENV=development

# External API Keys (optional - will fallback to mock data)
AAVE_API_KEY=
COMPOUND_API_KEY=
CURVE_API_KEY=
YEARN_API_KEY=
EOF
    print_info "Created main .env file"
fi

# Create deployments directory
mkdir -p deployments
print_status "Created deployments directory"

# Create demo data directory
mkdir -p demo
cat > demo/portfolio-data.json << EOF
{
  "demo_portfolio": {
    "address": "0x742d35Cc6634C0532925a3b8D35Cc6634C0532925",
    "totalValue": 10000,
    "currentYield": 3.2,
    "protocol": "Aave",
    "riskProfile": 2,
    "autoRebalanceEnabled": true,
    "lastRebalance": "2024-01-15T10:30:00Z"
  },
  "yield_opportunities": {
    "Aave": { "apy": 3.2, "tvl": 2500000000, "riskScore": 2 },
    "Compound": { "apy": 7.8, "tvl": 1800000000, "riskScore": 2 },
    "Curve": { "apy": 5.4, "tvl": 850000000, "riskScore": 3 },
    "Yearn": { "apy": 6.4, "tvl": 650000000, "riskScore": 3 },
    "Uniswap": { "apy": 4.2, "tvl": 420000000, "riskScore": 4 }
  }
}
EOF
print_status "Created demo data files"

# Create start scripts
cat > start-dev.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting DeFi Autopilot development servers..."

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

# Wait a moment for backend to start
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

chmod +x start-dev.sh
print_status "Created development start script"

# Create deployment helper script
cat > deploy.sh << 'EOF'
#!/bin/bash

echo "🚀 Deploying DeFi Autopilot to Flare testnet..."

# Check if .env has private key
if ! grep -q "PRIVATE_KEY=" .env || grep -q "your_private_key_here" .env; then
    echo "❌ Please add your private key to .env file first"
    exit 1
fi

# Compile contracts
echo "📝 Compiling contracts..."
npx hardhat compile

# Deploy to testnet
echo "🚀 Deploying to Flare testnet..."
npx hardhat run deployment/deploy.js --network flareTestnet

echo "✅ Deployment complete!"
echo "📝 Check deployments/ folder for contract addresses"
echo "🔧 Update your .env files with the new contract addresses"
EOF

chmod +x deploy.sh
print_status "Created deployment script"

# Create test script
cat > test.sh << 'EOF'
#!/bin/bash

echo "🧪 Running DeFi Autopilot tests..."

# Test smart contracts
echo "Testing smart contracts..."
npx hardhat test

# Test backend API (if running)
echo "Testing backend API..."
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend API is responsive"
    curl -s http://localhost:3001/api/yields | head -5
else
    echo "⚠️  Backend API not running. Start with ./start-dev.sh first"
fi

echo "✅ Tests complete!"
EOF

chmod +x test.sh
print_status "Created test script"

# Final setup completion
print_status "Setup completed successfully!"
echo ""
echo "=================================================="
echo "🎉 DeFi Autopilot is ready for development!"
echo "=================================================="
echo ""
echo "📋 Next steps:"
echo "1. Add your private key to .env file"
echo "2. Get Flare testnet tokens: https://coston2-faucet.flare.network/"
echo "3. Deploy contracts: ./deploy.sh"
echo "4. Start development servers: ./start-dev.sh"
echo "5. Open http://localhost:3000 to see the dashboard"
echo ""
echo "🔗 Useful links:"
echo "   • Flare testnet explorer: https://coston2-explorer.flare.network/"
echo "   • XRPL testnet explorer: https://testnet.xrpl.org/"
echo "   • Documentation: README.md"
echo ""
echo "🆘 Need help? Check the README.md or contact the team"
echo ""
print_status "Happy building! 🚀"
