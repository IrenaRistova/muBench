#!/bin/bash

# Script to set up port forwarding for the muBench nginx gateway service ON THE SERVER
# This is for the ACTUAL muBench deployment (not the Python standalone gateway used for POC)
# This should be run INSIDE the mubench container or on the server with kubectl access
# 
# Usage:
#   docker exec -it mubench bash -c "cd /root/muBench && ./scripts/mubench-gateway-tunnel.sh"
#   OR if running directly on server: ./scripts/mubench-gateway-tunnel.sh
#   OR use convenience script: ./scripts/start-mubench-gateway-tunnel.sh

set -e

NAMESPACE="${1:-default}"
GATEWAY_SVC="${2:-gw-nginx}"
LOCAL_PORT="${3:-9090}"
SVC_PORT="${4:-80}"

echo "=========================================="
echo "muBench Gateway Port-Forward Setup (Server-side)"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "Gateway Service: $GATEWAY_SVC"
echo "Local Port: $LOCAL_PORT"
echo "Service Port: $SVC_PORT"
echo "=========================================="
echo ""

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found"
    exit 1
fi

# Check if service exists
if ! kubectl get svc "$GATEWAY_SVC" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "Error: Service '$GATEWAY_SVC' not found in namespace '$NAMESPACE'"
    echo ""
    echo "Available services:"
    kubectl get svc -n "$NAMESPACE"
    exit 1
fi

echo "✓ Gateway service '$GATEWAY_SVC' found"
echo ""

# Check for existing port-forward processes
echo "Checking for existing port-forward processes..."
if command -v ps >/dev/null 2>&1; then
    EXISTING_PF=$(ps aux | grep "kubectl port-forward.*$GATEWAY_SVC" | grep -v grep || true)
    if [ -n "$EXISTING_PF" ]; then
        echo "Found existing port-forward:"
        echo "$EXISTING_PF"
        echo ""
        echo "Cleaning up existing port-forward..."
        pkill -f "kubectl port-forward.*$GATEWAY_SVC" || true
        sleep 2
    fi
else
    echo "  (ps command not available - skipping check)"
    # Try to kill anyway using pkill
    pkill -f "kubectl port-forward.*$GATEWAY_SVC" 2>/dev/null || true
    sleep 1
fi

# Check if port is in use (only if tools are available)
if command -v lsof >/dev/null 2>&1; then
    PORT_IN_USE=$(lsof -ti:$LOCAL_PORT 2>/dev/null || true)
    if [ -n "$PORT_IN_USE" ]; then
        echo "Port $LOCAL_PORT is in use by PID: $PORT_IN_USE"
        echo "Killing process..."
        kill -9 "$PORT_IN_USE" 2>/dev/null || true
        sleep 1
    fi
elif command -v fuser >/dev/null 2>&1; then
    if fuser -n tcp $LOCAL_PORT >/dev/null 2>&1; then
        echo "Port $LOCAL_PORT is in use, killing..."
        fuser -k -n tcp $LOCAL_PORT 2>/dev/null || true
        sleep 1
    fi
else
    echo "  (lsof/fuser not available - skipping port check)"
fi

# Start port forwarding
echo "Starting port-forward: kubectl port-forward svc/$GATEWAY_SVC $LOCAL_PORT:$SVC_PORT -n $NAMESPACE"
echo ""

kubectl port-forward svc/$GATEWAY_SVC $LOCAL_PORT:$SVC_PORT -n $NAMESPACE &
PF_PID=$!

sleep 3

# Verify port-forward by testing the connection (more reliable than checking process)
echo "Verifying port-forward..."
VERIFIED=false

if command -v curl >/dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:$LOCAL_PORT/s0" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        VERIFIED=true
        echo "✓ Port-forward is working! (HTTP $HTTP_CODE)"
    else
        echo "⚠ Connection test failed (HTTP $HTTP_CODE)"
        echo "  Port-forward may still be starting or services may not be ready"
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q --spider --timeout=2 "http://localhost:$LOCAL_PORT/s0" 2>/dev/null; then
        VERIFIED=true
        echo "✓ Port-forward is working!"
    else
        echo "⚠ Connection test failed"
    fi
else
    # If no curl/wget, assume it's working if we got this far (port-forward started)
    VERIFIED=true
    echo "✓ Port-forward started (cannot verify without curl/wget)"
fi

echo ""
echo "Gateway is now accessible at: http://localhost:$LOCAL_PORT"
echo ""
echo "Test locally with:"
echo "  curl -v http://localhost:$LOCAL_PORT/s0"
echo ""
echo "On your host machine, run:"
echo "  ./scripts/gateway-tunnel-local.sh"
echo ""
echo "Or manually:"
echo "  ssh -N -L $LOCAL_PORT:localhost:$LOCAL_PORT gl3"
echo ""
echo "Port-forward is running (PID: $PF_PID)"
echo "To stop: Press Ctrl+C or run: pkill -f 'kubectl port-forward.*$GATEWAY_SVC'"
echo ""

if [ "$VERIFIED" = false ]; then
    echo "⚠ Note: Connection test failed, but port-forward may still work"
    echo "  Check if gateway service is ready: kubectl get svc $GATEWAY_SVC -n $NAMESPACE"
    echo "  Check if gateway pod is running: kubectl get pods -n $NAMESPACE | grep gw-nginx"
    echo ""
fi

echo "Port-forward is active. Press Ctrl+C to stop..."
# Keep script running to maintain port-forward
wait $PF_PID

