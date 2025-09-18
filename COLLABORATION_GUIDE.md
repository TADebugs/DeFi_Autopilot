# 🤝 DeFi Autopilot Collaboration Guide

## Setting Up Team Development

### 1. **GitHub Repository Setup**

```bash
# Initialize git repository (if not already done)
cd /Users/tanmaydesai/hackathon/EasyA_x_Flare/DeFi_Autopilot
git init

# Add all files
git add .
git commit -m "Initial DeFi Autopilot project setup"

# Create GitHub repository and push
git remote add origin https://github.com/YOUR_USERNAME/DeFi_Autopilot.git
git branch -M main
git push -u origin main
```

### 2. **Inviting Your Frontend Collaborator**

1. **Add as GitHub Collaborator:**
   - Go to your GitHub repo → Settings → Collaborators
   - Click "Add people" and invite by username/email
   - Give them "Write" access

2. **Share Repository:**
   ```bash
   # Your collaborator runs:
   git clone https://github.com/YOUR_USERNAME/DeFi_Autopilot.git
   cd DeFi_Autopilot
   ```

## 🚀 Simultaneous Cursor Development

### **Option 1: Cursor + GitHub (Recommended)**

Both developers work with individual Cursor instances:

**You (Backend/Smart Contracts):**
```bash
# Your workflow
git checkout main
git pull origin main
git checkout -b feature/smart-contracts-enhancement
# Make changes...
git add .
git commit -m "Add new rebalancing features"
git push origin feature/smart-contracts-enhancement
# Create PR on GitHub
```

**Frontend Developer:**
```bash
# Their workflow  
git checkout main
git pull origin main
git checkout -b feature/ui-redesign
# Work on frontend...
git add frontend/
git commit -m "Improve dashboard design"
git push origin feature/ui-redesign
# Create PR on GitHub
```

### **Option 2: Cursor + Live Share (Real-time)**

For real-time collaboration:

1. **Install Live Share Extension in Cursor:**
   - Open Cursor
   - Go to Extensions (Cmd+Shift+X)
   - Search "Live Share" 
   - Install Microsoft Live Share

2. **Start Collaboration Session:**
   ```bash
   # Host (you) starts session
   Cmd+Shift+P → "Live Share: Start Collaboration Session"
   # Share the link with your collaborator
   ```

3. **Join Session:**
   ```bash
   # Collaborator joins
   Cmd+Shift+P → "Live Share: Join Collaboration Session"
   # Paste the shared link
   ```

## 📁 Project Structure for Collaboration

```
DeFi_Autopilot/
├── 🔧 contracts/          # Your domain (Smart Contracts)
├── 🖥️  backend/           # Your domain (AI Engine)  
├── 🎨 frontend/           # Collaborator's domain
├── 📝 docs/              # Shared documentation
├── 🧪 test/              # Shared testing
└── 🚀 deployment/        # Your domain (Deployment)
```

## 🔄 Workflow Best Practices

### **Branch Strategy**
```bash
main                    # Production-ready code
├── develop            # Integration branch
├── feature/backend-*  # Your backend features
├── feature/frontend-* # Frontend features
├── feature/contracts-*# Smart contract features
└── hotfix/*          # Emergency fixes
```

### **Commit Conventions**
```bash
# Use conventional commits
feat(frontend): add portfolio overview component
fix(backend): resolve yield calculation bug
docs: update API documentation
style(frontend): improve button animations
refactor(contracts): optimize gas usage
```

### **Development Environment Sync**

Create a shared environment setup:

```bash
# Both developers run the same setup
./setup.sh

# Use same Node.js version (via .nvmrc)
echo "18.17.0" > .nvmrc
nvm use  # Both use same Node version
```

## 🛠️ Cursor-Specific Collaboration Features

### **1. Shared Settings**
Create `.vscode/settings.json`:
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.preferences.importModuleSpecifier": "relative",
  "javascript.preferences.importModuleSpecifier": "relative",
  "emmet.includeLanguages": {
    "javascript": "javascriptreact"
  },
  "files.associations": {
    "*.sol": "solidity"
  },
  "solidity.compileUsingRemoteVersion": "v0.8.19+commit.7dd6d404"
}
```

### **2. Shared Extensions**
Create `.vscode/extensions.json`:
```json
{
  "recommendations": [
    "ms-vscode.vscode-typescript-next",
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "ms-vscode.vscode-json",
    "JuanBlanco.solidity",
    "ms-vsliveshare.vsliveshare"
  ]
}
```

## 🔐 Environment Variables Management

### **Shared Template (.env.example):**
```bash
# Blockchain Configuration
PRIVATE_KEY=your_private_key_here
FLARE_RPC_URL=https://coston2-api.flare.network/ext/bc/C/rpc

# Contract Addresses (shared after deployment)
PORTFOLIO_MANAGER_ADDRESS=0x...
YIELD_ORACLE_ADDRESS=0x...
REBALANCING_ENGINE_ADDRESS=0x...

# Frontend Configuration
REACT_APP_API_URL=http://localhost:3001
REACT_APP_FLARE_CHAIN_ID=114
```

### **Individual Setup:**
```bash
# Each developer copies and customizes
cp .env.example .env
# Add your own private key, API keys, etc.
```

## 🚀 Development Workflow

### **Daily Workflow:**
```bash
# Morning sync (both developers)
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Work on your domain
# Backend dev: work on backend/ and contracts/
# Frontend dev: work on frontend/

# Regular commits
git add .
git commit -m "descriptive commit message"

# Push and create PR
git push origin feature/your-feature-name
```

### **Integration Testing:**
```bash
# Test full stack integration
npm run deploy        # Deploy contracts
npm run backend       # Start backend API  
npm run frontend      # Start frontend
# Test the complete flow together
```

## 📱 Communication Setup

### **Development Communication:**
- **Slack/Discord**: Daily standups and quick questions
- **GitHub Issues**: Feature requests and bug tracking
- **GitHub PRs**: Code review and discussion
- **Live Share**: Real-time pair programming sessions

### **Code Review Process:**
1. Create feature branch
2. Make changes and test locally
3. Create PR with clear description
4. Request review from other developer
5. Address feedback and merge

## 🎯 Frontend Developer Onboarding

### **Quick Start for Frontend Dev:**
```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/DeFi_Autopilot.git
cd DeFi_Autopilot

# 2. Run setup script
./setup.sh

# 3. Focus on frontend
cd frontend
npm install
npm start

# 4. Backend API (for testing)
# Ask main dev to start backend or use mock data
```

### **Frontend-Specific Files:**
```bash
frontend/
├── src/
│   ├── components/     # React components
│   ├── hooks/         # Custom React hooks  
│   ├── utils/         # Utility functions
│   ├── styles/        # CSS/styling
│   └── assets/        # Images, fonts, etc.
├── public/            # Static assets
└── package.json       # Frontend dependencies
```

## 🔧 Troubleshooting Common Issues

### **Port Conflicts:**
```bash
# If ports are in use
Backend: PORT=3002 npm run dev
Frontend: PORT=3001 npm start
```

### **Environment Sync Issues:**
```bash
# Ensure same Node version
nvm use 18.17.0

# Clear and reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### **Git Merge Conflicts:**
```bash
# Resolve conflicts in Cursor
git status
# Open conflicted files in Cursor
# Resolve conflicts using Cursor's merge editor
git add .
git commit -m "resolve merge conflicts"
```

## 📋 Checklist for Collaborator Setup

- [ ] GitHub access granted
- [ ] Repository cloned locally
- [ ] Cursor IDE installed with recommended extensions
- [ ] Node.js 18+ installed
- [ ] Setup script executed successfully
- [ ] Environment variables configured
- [ ] Frontend development server running
- [ ] Communication channels established
- [ ] First test commit pushed

## 🎉 Success Metrics

- Both developers can work simultaneously without conflicts
- Code reviews happen within 24 hours
- Integration testing works seamlessly
- Demo preparation is collaborative
- Hackathon submission is polished and professional

---

**Ready to build the future of DeFi together! 🚀**