#!/bin/bash
# Script to start port forward for Shelf Check application

NAMESPACE="cls"
SERVICE="shelf-check-service"
LOCAL_PORT=8080

echo "🚀 Starting port forward for Shelf Check application..."
echo ""

# Check if port is already in use
if lsof -i :$LOCAL_PORT >/dev/null 2>&1; then
    echo "⚠️  Port $LOCAL_PORT is already in use"
    echo "   Killing existing port forward..."
    pkill -f "kubectl port-forward.*$LOCAL_PORT" || true
    sleep 2
fi

# Check if service exists
if ! kubectl get svc -n $NAMESPACE $SERVICE >/dev/null 2>&1; then
    echo "❌ Service $SERVICE not found in namespace $NAMESPACE"
    exit 1
fi

# Check if pods are ready
READY_PODS=$(kubectl get pods -n $NAMESPACE -l app=shelf-check,component=web --no-headers 2>/dev/null | grep -c "1/1" || echo "0")
if [ "$READY_PODS" -eq "0" ]; then
    echo "⚠️  Warning: No ready pods found"
    echo "   Continuing anyway..."
fi

# Start port forward in background
echo "📡 Forwarding port $LOCAL_PORT -> $SERVICE:80"
kubectl port-forward -n $NAMESPACE svc/$SERVICE $LOCAL_PORT:80 > /tmp/shelf-check-port-forward.log 2>&1 &
PF_PID=$!

# Wait a moment and check if it started
sleep 3
if kill -0 $PF_PID 2>/dev/null; then
    echo "✅ Port forward started successfully!"
    echo ""
    echo "🌐 Access your application at:"
    echo "   http://localhost:$LOCAL_PORT"
    echo ""
    echo "📝 Available endpoints:"
    echo "   - Home:      http://localhost:$LOCAL_PORT/"
    echo "   - Login:     http://localhost:$LOCAL_PORT/login"
    echo "   - Metrics:   http://localhost:$LOCAL_PORT/metrics"
    echo ""
    echo "🛑 To stop the port forward:"
    echo "   kill $PF_PID"
    echo "   or run: pkill -f 'kubectl port-forward.*$LOCAL_PORT'"
    echo ""
    echo "📋 Logs are in: /tmp/shelf-check-port-forward.log"
    echo ""
    echo "💡 Tip: Keep this terminal open or run in background with:"
    echo "   nohup ./start-port-forward.sh &"
else
    echo "❌ Port forward failed to start"
    echo "   Check logs: cat /tmp/shelf-check-port-forward.log"
    exit 1
fi

