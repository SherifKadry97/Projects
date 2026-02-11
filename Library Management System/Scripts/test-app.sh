#!/bin/bash
# Quick test script for Shelf Check Application

set -e

NAMESPACE="cls"
SERVICE="shelf-check-service"
LOCAL_PORT=8080

echo "🧪 Testing Shelf Check Application"
echo "===================================="
echo ""

# 1. Check pod status
echo "1️⃣ Checking pod status..."
echo "---------------------------"
kubectl get pods -n $NAMESPACE -l app=shelf-check,component=web
echo ""

# 2. Check if any pod is ready
READY_POD=$(kubectl get pods -n $NAMESPACE -l app=shelf-check,component=web -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')

if [ -z "$READY_POD" ]; then
    echo "⚠️  No running pods found. Checking logs..."
    echo ""
    kubectl logs -n $NAMESPACE -l app=shelf-check,component=web --tail=20
    echo ""
    echo "❌ Application pods are not ready. Please check logs above."
    exit 1
fi

echo "✅ Found running pod: $READY_POD"
echo ""

# 3. Check pod logs
echo "2️⃣ Checking application logs..."
echo "---------------------------------"
kubectl logs -n $NAMESPACE $READY_POD --tail=10
echo ""

# 4. Start port forward
echo "3️⃣ Starting port forward (background)..."
echo "------------------------------------------"
kubectl port-forward -n $NAMESPACE svc/$SERVICE $LOCAL_PORT:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 5

# Check if port forward is working
if ! kill -0 $PF_PID 2>/dev/null; then
    echo "❌ Port forward failed. Trying direct pod port forward..."
    kubectl port-forward -n $NAMESPACE $READY_POD $LOCAL_PORT:5000 > /dev/null 2>&1 &
    PF_PID=$!
    sleep 3
fi

echo "✅ Port forward started (PID: $PF_PID)"
echo "   Access at: http://localhost:$LOCAL_PORT"
echo ""

# 5. Test endpoints
echo "4️⃣ Testing endpoints..."
echo "----------------------"

# Test home page
echo -n "   Home page (/)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$LOCAL_PORT/ || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ OK (HTTP $HTTP_CODE)"
else
    echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

# Test metrics
echo -n "   Metrics (/metrics)... "
if curl -s http://localhost:$LOCAL_PORT/metrics 2>/dev/null | grep -q "http_requests_total"; then
    echo "✅ OK"
else
    echo "❌ FAILED or not available"
fi

# Test login page
echo -n "   Login page (/login)... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$LOCAL_PORT/login || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ OK (HTTP $HTTP_CODE)"
else
    echo "❌ FAILED (HTTP $HTTP_CODE)"
fi

echo ""

# 6. Show service info
echo "5️⃣ Service information..."
echo "-------------------------"
kubectl get svc -n $NAMESPACE $SERVICE
echo ""

# 7. Cleanup
echo "6️⃣ Cleaning up..."
kill $PF_PID 2>/dev/null || true
echo "✅ Port forward stopped"
echo ""

echo "===================================="
echo "✅ Testing complete!"
echo ""
echo "To access the application manually:"
echo "  kubectl port-forward -n $NAMESPACE svc/$SERVICE $LOCAL_PORT:80"
echo "  Then open: http://localhost:$LOCAL_PORT"
echo ""

