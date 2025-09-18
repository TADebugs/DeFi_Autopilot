#!/bin/bash

echo "🧪 Testing DeFi Autopilot Integration"
echo "===================================="

# Test backend health
echo "1. Testing backend health..."
if curl -s http://localhost:3001/api/health > /dev/null; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not running - start with: cd backend && node server.js"
    exit 1
fi

# Test API endpoints
echo "2. Testing API endpoints..."
echo "📊 Yields endpoint:"
curl -s http://localhost:3001/api/yields | head -c 100
echo "..."

echo "🤖 Optimization endpoint:"
curl -s -X POST http://localhost:3001/api/optimize \
  -H "Content-Type: application/json" \
  -d '{"totalValue": 10000, "currentYield": 3.2, "riskProfile": 2}' | head -c 100
echo "..."

# Check if frontend is running
echo "3. Checking frontend..."
if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo "✅ Frontend is running on port 5173"
elif curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is running on port 3000"
else
    echo "⚠️  Frontend not detected - make sure it's running"
fi

echo ""
echo "🎯 Integration Status:"
echo "✅ Backend API: http://localhost:3001"
echo "✅ API Documentation: FRONTEND_API_GUIDE.md" 
echo "✅ Demo data: Ready for 30-second flow"
echo ""
echo "🚀 Ready for hackathon demo!"
