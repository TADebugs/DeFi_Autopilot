# 🤖 Cursor AI Agent Coordination Guide

## Real-Time Coordination Strategies

### **1. Shared Context Files**
Both Cursor instances will have access to these coordination files:
- `.cursorrules` - AI assistant behavior and project context
- `.cursor/rules` - Development rules and architecture decisions
- `DEVELOPMENT_SYNC.md` - This coordination guide
- `COLLABORATION_GUIDE.md` - Human developer collaboration

### **2. Live Share + AI Coordination**
```bash
# Install Live Share extension in both Cursor instances
# Host starts session:
Cmd+Shift+P → "Live Share: Start Collaboration Session"

# Both AI assistants can see:
- Real-time code changes
- Active file being worked on
- Cursor positions and selections
- Terminal outputs
```

### **3. Smart Branching Strategy**
```bash
# Backend Developer (You + Cursor AI)
git checkout -b backend/ai-optimization-v2
# Work on: backend/, contracts/, deployment/

# Frontend Developer (Collaborator + Cursor AI) 
git checkout -b frontend/dashboard-redesign
# Work on: frontend/src/, styling, components/

# Integration branch for testing
git checkout -b integration/demo-prep
# Merge both branches for testing
```

### **4. AI Context Synchronization**

#### **Shared Project State File**
```json
// .cursor/project-state.json (auto-updated)
{
  "currentSprint": "hackathon-demo-prep",
  "activeFeatures": {
    "backend": "AI yield optimization algorithms",
    "frontend": "Portfolio dashboard redesign",
    "integration": "30-second demo flow"
  },
  "completedTasks": [
    "Smart contract deployment",
    "Basic AI engine setup",
    "React component structure"
  ],
  "nextPriorities": [
    "Demo data preparation",
    "UI polish for judges",
    "Integration testing"
  ],
  "demoRequirements": {
    "portfolioValue": 10000,
    "currentYield": 3.2,
    "targetYield": 7.8,
    "executionTime": 8,
    "profitMargin": 457
  }
}
```

#### **Cross-Instance Communication**
```bash
# Create coordination comments in code
// @CURSOR_SYNC: Backend AI - yield calculation updated, frontend needs new API endpoint
// @FRONTEND_TODO: Update dashboard to show new profit metrics
// @INTEGRATION_TEST: Verify demo flow works end-to-end

# Use consistent variable names across instances
const DEMO_PORTFOLIO_VALUE = 10000;
const DEMO_CURRENT_YIELD = 3.2;
const DEMO_TARGET_YIELD = 7.8;
```

### **5. Automated Coordination Scripts**

#### **Sync Script for Both Instances**
```bash
# scripts/sync-development.sh
#!/bin/bash

echo "🔄 Syncing DeFi Autopilot development state..."

# Pull latest changes
git fetch origin
git status

# Update project state
echo "📊 Current branch: $(git branch --show-current)"
echo "🔄 Latest commits:"
git log --oneline -5

# Check for conflicts
if git status --porcelain | grep -q "^UU"; then
    echo "⚠️  MERGE CONFLICTS DETECTED - Resolve before continuing"
fi

# Update AI context
echo "🤖 Updating AI context..."
echo "Last sync: $(date)" >> .cursor/last-sync.log

# Test integration points
echo "🧪 Testing integration..."
if [ -f "backend/server.js" ] && [ -f "frontend/src/App.js" ]; then
    echo "✅ Backend and Frontend files present"
else
    echo "❌ Missing critical files"
fi
```

### **6. Real-Time Status Dashboard**

#### **Development Status API**
```javascript
// scripts/dev-status-server.js
const express = require('express');
const fs = require('fs');
const app = express();

app.get('/dev-status', (req, res) => {
    const status = {
        timestamp: new Date().toISOString(),
        backend: {
            server: fs.existsSync('backend/server.js') ? 'ready' : 'missing',
            contracts: fs.existsSync('contracts/PortfolioManager.sol') ? 'deployed' : 'pending'
        },
        frontend: {
            dashboard: fs.existsSync('frontend/src/App.js') ? 'ready' : 'missing',
            styling: fs.existsSync('frontend/src/App.css') ? 'ready' : 'pending'
        },
        demo: {
            dataReady: fs.existsSync('demo/portfolio-data.json'),
            scriptsReady: fs.existsSync('demo/demo-script.md')
        }
    };
    res.json(status);
});

app.listen(3333, () => {
    console.log('🔄 Dev status server running on http://localhost:3333/dev-status');
});
```

### **7. AI Prompt Coordination Templates**

#### **For Backend Cursor Instance:**
```
Context: You're working on DeFi Autopilot backend/smart contracts. 
Frontend team is working on React dashboard simultaneously.

Current focus: AI yield optimization and smart contract security
Integration points: API endpoints for frontend, contract ABIs
Demo requirements: 30-second flow showing $457 profit calculation

Always consider:
- API compatibility with frontend
- Gas optimization for demo
- Error handling for live presentation
- Mock data fallbacks
```

#### **For Frontend Cursor Instance:**
```
Context: You're working on DeFi Autopilot React frontend.
Backend team is handling smart contracts and AI engine.

Current focus: Professional dashboard UI and Web3 integration
Integration points: Backend API calls, wallet connection, real-time updates
Demo requirements: Smooth 30-second flow with clear profit display

Always consider:
- Mobile responsiveness
- Loading states and error handling
- Professional design for judges
- Demo data visualization
```

### **8. Conflict Resolution Protocol**

#### **When Both AIs Work on Same Area:**
```bash
# 1. Check who's working where
git branch -a
git log --oneline --graph

# 2. Coordinate via comments
// @CURSOR_COORDINATION: Backend AI working on yield calculations
// @FRONTEND_AI: Please use /api/yields endpoint for live data

# 3. Test integration frequently
npm run test-integration

# 4. Use feature flags for experimental code
const FEATURE_FLAGS = {
    NEW_YIELD_ALGORITHM: process.env.NODE_ENV === 'development',
    ENHANCED_UI: true,
    DEMO_MODE: true
};
```

### **9. Demo Coordination Checklist**

```markdown
## Pre-Demo Sync (Both AIs)
- [ ] Backend API returns demo data consistently
- [ ] Frontend displays profit calculations correctly
- [ ] 8-second rebalancing animation works
- [ ] Error fallbacks are in place
- [ ] Mobile responsiveness verified
- [ ] All environment variables set
- [ ] Git branches merged and tested

## During Demo Coordination
- [ ] Backend AI: Monitor API responses
- [ ] Frontend AI: Ensure smooth UI transitions
- [ ] Both: Be ready with fallback explanations
```

### **10. Advanced Cursor Features for Coordination**

#### **Shared Workspace Settings:**
```json
// .vscode/settings.json (shared)
{
  "cursor.ai.contextFiles": [
    ".cursorrules",
    "DEVELOPMENT_SYNC.md",
    "demo/portfolio-data.json",
    "contracts/PortfolioManager.sol",
    "backend/server.js",
    "frontend/src/App.js"
  ],
  "cursor.ai.collaborationMode": true,
  "cursor.ai.sharedContext": true
}
```

## 🚀 **Implementation Steps**

1. **Both developers install Live Share extension**
2. **Share the repository and coordination files**
3. **Run sync script before each development session**
4. **Use consistent naming and commenting conventions**
5. **Test integration every 30 minutes during hackathon**
6. **Maintain shared project state file**

This setup ensures both Cursor AI instances work in harmony while maintaining clear domain boundaries! 🤖🤝🤖
