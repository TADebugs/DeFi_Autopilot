#!/bin/bash

# DeFi Autopilot - Development Sync Script
# Coordinates between multiple Cursor instances

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Syncing DeFi Autopilot development state...${NC}"
echo "=================================================="

# Create sync directory if it doesn't exist
mkdir -p .cursor

# Update project state
CURRENT_BRANCH=$(git branch --show-current)
LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s (%an)")

echo -e "${GREEN}📊 Current branch:${NC} $CURRENT_BRANCH"
echo -e "${GREEN}🔄 Latest commit:${NC} $LAST_COMMIT"

# Pull latest changes
echo -e "${BLUE}📥 Pulling latest changes...${NC}"
git fetch origin

# Check for conflicts
if git status --porcelain | grep -q "^UU"; then
    echo -e "${RED}⚠️  MERGE CONFLICTS DETECTED${NC}"
    echo "Please resolve conflicts before continuing development"
    exit 1
fi

# Check integration points
echo -e "${BLUE}🧪 Checking integration points...${NC}"

# Backend checks
if [ -f "backend/server.js" ]; then
    echo -e "${GREEN}✅ Backend server ready${NC}"
else
    echo -e "${RED}❌ Backend server missing${NC}"
fi

if [ -f "contracts/PortfolioManager.sol" ]; then
    echo -e "${GREEN}✅ Smart contracts ready${NC}"
else
    echo -e "${RED}❌ Smart contracts missing${NC}"
fi

# Frontend checks
if [ -f "frontend/src/App.js" ]; then
    echo -e "${GREEN}✅ Frontend dashboard ready${NC}"
else
    echo -e "${RED}❌ Frontend dashboard missing${NC}"
fi

if [ -f "frontend/src/App.css" ]; then
    echo -e "${GREEN}✅ Frontend styling ready${NC}"
else
    echo -e "${RED}❌ Frontend styling missing${NC}"
fi

# Demo readiness checks
if [ -d "demo" ]; then
    echo -e "${GREEN}✅ Demo directory exists${NC}"
else
    echo -e "${YELLOW}⚠️  Demo directory missing - creating...${NC}"
    mkdir -p demo
fi

# Update AI context files
echo -e "${BLUE}🤖 Updating AI context...${NC}"
echo "Last sync: $(date)" >> .cursor/last-sync.log

# Create project state file
cat > .cursor/project-state.json << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentBranch": "$CURRENT_BRANCH",
  "lastCommit": "$LAST_COMMIT",
  "developmentPhase": "hackathon-preparation",
  "integrationStatus": {
    "backend": $([ -f "backend/server.js" ] && echo "true" || echo "false"),
    "contracts": $([ -f "contracts/PortfolioManager.sol" ] && echo "true" || echo "false"),
    "frontend": $([ -f "frontend/src/App.js" ] && echo "true" || echo "false"),
    "demo": $([ -d "demo" ] && echo "true" || echo "false")
  },
  "demoRequirements": {
    "portfolioValue": 10000,
    "currentYield": 3.2,
    "targetYield": 7.8,
    "executionTime": 8,
    "expectedProfit": 457
  },
  "nextSteps": [
    "Test integration between backend and frontend",
    "Prepare demo data and scripts",
    "Verify 30-second demo flow",
    "Polish UI for judge presentation"
  ]
}
EOF

echo -e "${GREEN}✅ Project state updated${NC}"

# Check for running development servers
echo -e "${BLUE}🔍 Checking development servers...${NC}"

if lsof -i :3001 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend server running on port 3001${NC}"
else
    echo -e "${YELLOW}⚠️  Backend server not running${NC}"
    echo "   Start with: cd backend && npm run dev"
fi

if lsof -i :3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend server running on port 3000${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend server not running${NC}"
    echo "   Start with: cd frontend && npm start"
fi

# Git status summary
echo -e "${BLUE}📋 Git status summary:${NC}"
git status --short

# Show recent activity from both domains
echo -e "${BLUE}📈 Recent development activity:${NC}"
echo "Backend changes:"
git log --oneline -3 --grep="backend\|contract\|api" || echo "No recent backend changes"

echo "Frontend changes:"
git log --oneline -3 --grep="frontend\|ui\|dashboard" || echo "No recent frontend changes"

# Coordination reminders
echo ""
echo -e "${YELLOW}🤖 Cursor AI Coordination Reminders:${NC}"
echo "• Backend AI: Focus on contracts/, backend/, deployment/"
echo "• Frontend AI: Focus on frontend/, styling, UI/UX"
echo "• Both: Test integration frequently"
echo "• Demo priority: 30-second flow must work flawlessly"
echo "• Use @CURSOR_SYNC comments for cross-instance communication"

echo ""
echo -e "${GREEN}🎯 Ready for coordinated development!${NC}"
echo "=================================================="
