#!/bin/bash

# Combined server-side port-forward script
# Sets up port-forwards for both muBench gateway and Prometheus
# This should be run inside the mubench container or on the server with kubectl access
# 
# Usage:
#   docker exec -it mubench bash -c "cd /root/muBench && ./scripts/combined-tunnels-server.sh [gateway-namespace] [prometheus-namespace]"
#   OR if running directly on server: ./scripts/combined-tunnels-server.sh

set -e

# Configuration
GATEWAY_NAMESPACE="${1:-default}"
GATEWAY_SVC="${2:-gw-nginx}"
GATEWAY_LOCAL_PORT="${3:-9090}"
GATEWAY_SVC_PORT="${4:-80}"

PROMETHEUS_NAMESPACE="${5:-monitoring}"
PROMETHEUS_SVC="${6:-prometheus-nodeport}"
PROMETHEUS_LOCAL_PORT="${7:-30000}"
PROMETHEUS_SVC_PORT="${8:-9090}"

echo "=========================================="
echo "muBench Combined Port-Forward Setup (Server-side)"
echo "=========================================="
echo "Gateway:"
echo "  Namespace: $GATEWAY_NAMESPACE"
echo "  Service: $GATEWAY_SVC"
echo "  Local Port: $GATEWAY_LOCAL_PORT"
echo "  Service Port: $GATEWAY_SVC_PORT"
echo ""
echo "Prometheus:"
echo "  Namespace: $PROMETHEUS_NAMESPACE"
echo "  Service: $PROMETHEUS_SVC"
echo "  Local Port: $PROMETHEUS_LOCAL_PORT"
echo "  Service Port: $PROMETHEUS_SVC_PORT"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found"
    exit 1
fi

# Function to check service exists
check_service() {
    local namespace=$1
    local service=$2
    local name=$3
    
    if ! kubectl get svc "$service" -n "$namespace" >/dev/null 2>&1; then
        echo "Error: $name service '$service' not found in namespace '$namespace'"
        echo ""
        echo "Available services in namespace '$namespace':"
        kubectl get svc -n "$namespace"
        return 1
    fi
    return 0
}

# Check both services
if ! check_service "$GATEWAY_NAMESPACE" "$GATEWAY_SVC" "Gateway"; then
    exit 1
fi

if ! check_service "$PROMETHEUS_NAMESPACE" "$PROMETHEUS_SVC" "Prometheus"; then
    exit 1
fi

echo "✓ Gateway service '$GATEWAY_SVC' found"
echo "✓ Prometheus service '$PROMETHEUS_SVC' found"
echo ""

# Function to cleanup existing port-forwards
cleanup_portforward() {
    local service=$1
    local name=$2
    
    echo "Checking for existing $name port-forward processes..."
    if command -v ps >/dev/null 2>&1; then
        EXISTING_PF=$(ps aux | grep "kubectl port-forward.*$service" | grep -v grep || true)
        if [ -n "$EXISTING_PF" ]; then
            echo "Found existing $name port-forward:"
            echo "$EXISTING_PF"
            echo ""
            echo "Cleaning up existing $name port-forward..."
            pkill -f "kubectl port-forward.*$service" || true
            sleep 1
        fi
    else
        pkill -f "kubectl port-forward.*$service" 2>/dev/null || true
    fi
}

# Function to check and free port
check_port() {
    local port=$1
    local name=$2
    
    if command -v lsof >/dev/null 2>&1; then
        PORT_IN_USE=$(lsof -ti:$port 2>/dev/null || true)
        if [ -n "$PORT_IN_USE" ]; then
            echo "Port $port ($name) is in use by PID: $PORT_IN_USE"
            echo "Killing process..."
            kill -9 "$PORT_IN_USE" 2>/dev/null || true
            sleep 1
        fi
    elif command -v fuser >/dev/null 2>&1; then
        if fuser -n tcp $port >/dev/null 2>&1; then
            echo "Port $port ($name) is in use, killing..."
            fuser -k -n tcp $port 2>/dev/null || true
            sleep 1
        fi
    fi
}

# Cleanup existing port-forwards
cleanup_portforward "$GATEWAY_SVC" "Gateway"
cleanup_portforward "$PROMETHEUS_SVC" "Prometheus"

# Check and free ports
check_port "$GATEWAY_LOCAL_PORT" "Gateway"
check_port "$PROMETHEUS_LOCAL_PORT" "Prometheus"

# Start Gateway port-forward
echo "Starting Gateway port-forward: kubectl port-forward svc/$GATEWAY_SVC $GATEWAY_LOCAL_PORT:$GATEWAY_SVC_PORT -n $GATEWAY_NAMESPACE"
kubectl port-forward svc/$GATEWAY_SVC $GATEWAY_LOCAL_PORT:$GATEWAY_SVC_PORT -n "$GATEWAY_NAMESPACE" &
GATEWAY_PF_PID=$!

# Start Prometheus port-forward
echo "Starting Prometheus port-forward: kubectl port-forward svc/$PROMETHEUS_SVC $PROMETHEUS_LOCAL_PORT:$PROMETHEUS_SVC_PORT -n $PROMETHEUS_NAMESPACE"
kubectl port-forward svc/$PROMETHEUS_SVC $PROMETHEUS_LOCAL_PORT:$PROMETHEUS_SVC_PORT -n "$PROMETHEUS_NAMESPACE" &
PROMETHEUS_PF_PID=$!

sleep 3

# Verify port-forwards
echo ""
echo "Verifying port-forwards..."
VERIFIED_GATEWAY=false
VERIFIED_PROMETHEUS=false

# Test Gateway
if command -v curl >/dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$GATEWAY_LOCAL_PORT/s0" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        VERIFIED_GATEWAY=true
        echo "✓ Gateway port-forward is working! (HTTP $HTTP_CODE)"
    else
        echo "⚠ Gateway connection test failed (HTTP $HTTP_CODE)"
    fi
else
    VERIFIED_GATEWAY=true
    echo "✓ Gateway port-forward started (cannot verify without curl)"
fi

# Test Prometheus
if command -v curl >/dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$PROMETHEUS_LOCAL_PORT/api/v1/status/config" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        VERIFIED_PROMETHEUS=true
        echo "✓ Prometheus port-forward is working! (HTTP $HTTP_CODE)"
    else
        echo "⚠ Prometheus connection test failed (HTTP $HTTP_CODE)"
    fi
else
    VERIFIED_PROMETHEUS=true
    echo "✓ Prometheus port-forward started (cannot verify without curl)"
fi

echo ""
echo "=========================================="
echo "Port-Forward Status"
echo "=========================================="
if [ "$VERIFIED_GATEWAY" = true ]; then
    echo "✓ Gateway: http://localhost:$GATEWAY_LOCAL_PORT (PID: $GATEWAY_PF_PID)"
else
    echo "⚠ Gateway: http://localhost:$GATEWAY_LOCAL_PORT (PID: $GATEWAY_PF_PID) - test failed"
fi

if [ "$VERIFIED_PROMETHEUS" = true ]; then
    echo "✓ Prometheus: http://localhost:$PROMETHEUS_LOCAL_PORT (PID: $PROMETHEUS_PF_PID)"
else
    echo "⚠ Prometheus: http://localhost:$PROMETHEUS_LOCAL_PORT (PID: $PROMETHEUS_PF_PID) - test failed"
fi

echo ""
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "Gateway (muBench application):"
echo "  URL: http://localhost:$GATEWAY_LOCAL_PORT"
echo "  Test: curl -v http://localhost:$GATEWAY_LOCAL_PORT/s0"
echo ""
echo "Prometheus:"
echo "  URL: http://localhost:$PROMETHEUS_LOCAL_PORT"
echo "  Test: curl http://localhost:$PROMETHEUS_LOCAL_PORT/api/v1/status/config"
echo ""
echo "On your host machine, run:"
echo "  ./scripts/gateway-tunnel-local.sh  # (if you have the combined tunnel script)"
echo "  OR use your combined SSH tunnel script"
echo ""
echo "Port-forwards are running:"
echo "  Gateway PID: $GATEWAY_PF_PID"
echo "  Prometheus PID: $PROMETHEUS_PF_PID"
echo ""
echo "To stop: Press Ctrl+C or run:"
echo "  pkill -f 'kubectl port-forward.*$GATEWAY_SVC'"
echo "  pkill -f 'kubectl port-forward.*$PROMETHEUS_SVC'"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping port-forwards..."
    kill $GATEWAY_PF_PID $PROMETHEUS_PF_PID 2>/dev/null || true
    wait $GATEWAY_PF_PID $PROMETHEUS_PF_PID 2>/dev/null || true
    echo "Port-forwards stopped."
    exit 0
}

# Trap Ctrl+C
trap cleanup INT TERM

echo "Both port-forwards are active. Press Ctrl+C to stop..."
# Keep script running to maintain port-forwards
wait $GATEWAY_PF_PID $PROMETHEUS_PF_PID

