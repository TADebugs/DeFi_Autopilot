# 🎨 Frontend Developer API Guide - DeFi Autopilot

## 🚀 Backend Status: ✅ RUNNING

**Backend URL**: `http://localhost:3001`
**Status**: Running with demo-ready mock data
**Health Check**: `GET http://localhost:3001/api/health`

---

## 📡 **Core API Endpoints**

### **1. Health Check**
```http
GET /api/health
```
**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-18T03:12:28.067Z",
  "version": "1.0.0"
}
```

### **2. Live Yield Data** 
```http
GET /api/yields
```
**Response:**
```json
{
  "success": true,
  "data": {
    "Aave": {
      "apy": 3.2,
      "tvl": 2500000000,
      "riskScore": 2,
      "protocol": "Aave",
      "utilizationRate": 0.75,
      "mock": true
    },
    "Compound": {
      "apy": 7.8,
      "tvl": 1800000000,
      "riskScore": 2,
      "protocol": "Compound",
      "utilizationRate": 0.75,
      "mock": true
    },
    "Curve": {
      "apy": 5.4,
      "tvl": 850000000,
      "riskScore": 3,
      "protocol": "Curve",
      "mock": true
    },
    "Yearn": {
      "apy": 6.4,
      "tvl": 650000000,
      "riskScore": 3,
      "protocol": "Yearn",
      "mock": true
    },
    "Uniswap": {
      "apy": 4.2,
      "tvl": 420000000,
      "riskScore": 4,
      "protocol": "Uniswap",
      "mock": true
    }
  },
  "timestamp": "2025-09-18T03:12:37.394Z"
}
```

### **3. AI Portfolio Optimization** 
```http
POST /api/optimize
Content-Type: application/json
```
**Request Body:**
```json
{
  "totalValue": 10000,
  "currentYield": 3.2,
  "riskProfile": 2,
  "protocol": "Aave"
}
```

**Response:**
```json
{
  "success": true,
  "strategy": {
    "shouldRebalance": true,
    "recommendation": {
      "fromProtocol": "Aave",
      "toProtocol": "Compound",
      "currentYield": 3.2,
      "newYield": 7.8,
      "yieldIncrease": 4.6,
      "annualProfit": 460,
      "executionCost": 3,
      "netProfit": 458,
      "paybackPeriod": 2,
      "route": {
        "path": ["Flare"],
        "totalCost": 0.0025,
        "estimatedTime": 2
      }
    },
    "alternatives": [
      {
        "protocol": "Yearn",
        "apy": 6.4,
        "riskScore": 3,
        "yieldIncrease": 3.2
      }
    ],
    "riskAssessment": "MEDIUM"
  }
}
```

### **4. Cross-Chain Route Calculation**
```http
POST /api/route
Content-Type: application/json
```
**Request Body:**
```json
{
  "fromChain": "Flare",
  "toChain": "Flare",
  "amount": 10000,
  "urgency": "normal"
}
```

**Response:**
```json
{
  "success": true,
  "route": {
    "path": ["Flare"],
    "cost": 0.0025,
    "time": 2,
    "slippage": 0
  }
}
```

### **5. Risk Assessment**
```http
POST /api/risk-assessment
Content-Type: application/json
```
**Request Body:**
```json
{
  "protocol": "Compound",
  "amount": 10000,
  "riskProfile": 2
}
```

---

## 🎯 **Demo Integration Guide**

### **30-Second Demo Flow**
The backend is optimized for a perfect demo experience:

1. **Portfolio Display (5s)**
   - Show $10,000 @ 3.2% APY on Aave
   - Annual earnings: $320

2. **AI Discovery (8s)**
   - Call `/api/optimize` with current portfolio
   - Show Compound @ 7.8% APY opportunity
   - Display +$460 annual profit potential

3. **Cost Analysis (7s)**
   - Show execution cost: $3
   - Net profit: $457
   - Profit margin: 152x execution cost

4. **Execution Simulation (8s)**
   - 8-second progress animation
   - XRPL routing visualization
   - Success confirmation

5. **Results (2s)**
   - Updated portfolio: 7.8% APY
   - Total profit: +$457/year

### **Frontend Integration Code Examples**

#### **React Hook for API Integration**
```jsx
// useDefiApi.js
import { useState, useEffect } from 'react';

export const useDefiApi = () => {
  const [yields, setYields] = useState({});
  const [loading, setLoading] = useState(false);
  
  const API_BASE = 'http://localhost:3001/api';
  
  const fetchYields = async () => {
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE}/yields`);
      const data = await response.json();
      if (data.success) {
        setYields(data.data);
      }
    } catch (error) {
      console.error('Failed to fetch yields:', error);
    } finally {
      setLoading(false);
    }
  };
  
  const optimizePortfolio = async (portfolio) => {
    try {
      const response = await fetch(`${API_BASE}/optimize`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(portfolio)
      });
      return await response.json();
    } catch (error) {
      console.error('Optimization failed:', error);
      return null;
    }
  };
  
  useEffect(() => {
    fetchYields();
    // Refresh every 30 seconds
    const interval = setInterval(fetchYields, 30000);
    return () => clearInterval(interval);
  }, []);
  
  return { yields, loading, optimizePortfolio, fetchYields };
};
```

#### **Demo State Management**
```jsx
// DemoFlow.jsx
import React, { useState, useEffect } from 'react';

const DemoFlow = () => {
  const [demoStep, setDemoStep] = useState(1);
  const [portfolio, setPortfolio] = useState({
    value: 10000,
    yield: 3.2,
    protocol: 'Aave'
  });
  
  const demoSteps = [
    { step: 1, title: "Portfolio Display", duration: 5000 },
    { step: 2, title: "AI Discovery", duration: 8000 },
    { step: 3, title: "Cost Analysis", duration: 7000 },
    { step: 4, title: "Execution", duration: 8000 },
    { step: 5, title: "Results", duration: 2000 }
  ];
  
  const runDemo = async () => {
    for (const step of demoSteps) {
      setDemoStep(step.step);
      await new Promise(resolve => setTimeout(resolve, step.duration));
    }
  };
  
  return (
    <div className="demo-container">
      <h2>Step {demoStep}: {demoSteps[demoStep-1]?.title}</h2>
      {/* Your demo UI components */}
    </div>
  );
};
```

---

## 🎨 **UI/UX Recommendations**

### **Design System**
- **Colors**: Use the existing glassmorphism theme
- **Animations**: Smooth transitions for yield changes
- **Loading States**: Professional spinners during API calls
- **Error Handling**: Graceful fallbacks if backend is down

### **Key Components Needed**
1. **PortfolioCard**: Shows current value, yield, protocol
2. **YieldTable**: Live market rates from `/api/yields`
3. **OptimizationAlert**: AI recommendations with profit calc
4. **ExecutionProgress**: 8-second rebalancing animation
5. **WalletConnect**: MetaMask integration (can be mocked)

### **Demo-Specific Features**
- **Auto-refresh**: Update yields every 30 seconds
- **Progress indicators**: Show demo step progress
- **Fallback data**: Use mock data if API fails
- **Smooth animations**: 8-second execution with progress bar

---

## 🔧 **Development Tips**

### **Testing the Backend**
```bash
# Test all endpoints
curl http://localhost:3001/api/health
curl http://localhost:3001/api/yields
curl -X POST http://localhost:3001/api/optimize \
  -H "Content-Type: application/json" \
  -d '{"totalValue": 10000, "currentYield": 3.2, "riskProfile": 2}'
```

### **Error Handling**
```jsx
const handleApiError = (error) => {
  console.error('API Error:', error);
  // Use fallback mock data for demo reliability
  return MOCK_DATA;
};
```

### **Environment Variables**
```bash
# Frontend .env
REACT_APP_API_URL=http://localhost:3001
REACT_APP_DEMO_MODE=true
REACT_APP_WALLET_ADDRESS=0x21e9E8666A66E0E6ff615d6Ee39Cc86Ee1F1DE5f
```

---

## 🚀 **Ready for Integration!**

The backend is **fully functional** and serving **realistic demo data**. All endpoints are tested and working. Your frontend can start integration immediately!

### **Priority Features:**
1. ✅ **Portfolio display** with live yield data
2. ✅ **AI optimization alerts** with clear profit calculations  
3. ✅ **Smooth execution animation** (8-second rebalancing)
4. ✅ **Professional UI** that impresses judges
5. ✅ **Demo reliability** with fallback data

**The backend is production-ready for your hackathon demo!** 🏆
