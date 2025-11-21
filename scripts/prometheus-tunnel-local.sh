#!/bin/bash

# Prometheus SSH tunnel script (host-side)
# Creates SSH tunnel from host machine to server for Prometheus access
# Usage: ./scripts/prometheus-tunnel-local.sh

set -e

SERVER="${1:-gl3}"
LOCAL_PORT="${2:-30000}"
REMOTE_PORT="${3:-30000}"

echo "=========================================="
echo "Prometheus SSH Tunnel (Host-side)"
echo "=========================================="
echo "Server: $SERVER"
echo "Local Port: $LOCAL_PORT"
echo "Remote Port: $REMOTE_PORT"
echo "=========================================="
echo ""

# Check for existing SSH tunnel
echo "Checking for existing SSH tunnel..."
EXISTING_TUNNEL=$(ps aux | grep "ssh.*-L.*$LOCAL_PORT" | grep -v grep || true)

if [ -n "$EXISTING_TUNNEL" ]; then
    echo "Found existing SSH tunnel:"
    echo "$EXISTING_TUNNEL"
    echo ""
    read -p "Kill existing tunnel and create new one? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Killing existing tunnel..."
        pkill -f "ssh.*-L.*$LOCAL_PORT" || true
        sleep 2
    else
        echo "Keeping existing tunnel. Exiting."
        exit 0
    fi
fi

# Check if port is in use
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
fi

# Create SSH tunnel
echo "Creating SSH tunnel: ssh -N -L $LOCAL_PORT:localhost:$REMOTE_PORT $SERVER"
echo ""
echo "This will forward:"
echo "  Host: localhost:$LOCAL_PORT → Server: localhost:$REMOTE_PORT"
echo ""
echo "After this tunnel is established, you can access Prometheus at:"
echo "  http://localhost:$LOCAL_PORT"
echo ""
echo "Test with:"
echo "  curl http://localhost:$LOCAL_PORT/api/v1/status/config"
echo ""
echo "Press Ctrl+C to stop the tunnel"
echo ""

ssh -N -L "$LOCAL_PORT:localhost:$REMOTE_PORT" "$SERVER"

