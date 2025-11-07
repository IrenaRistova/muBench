#!/bin/bash

# Script to set up SSH tunnel from host machine to gl3 server
# for accessing the muBench nginx gateway
# 
# Prerequisites:
# 1. Run gateway-tunnel.sh OR gateway-tunnel-standalone-python.sh on gl3 server first
# 2. Ensure you can SSH to gl3 through the jump host

echo "Checking existing gateway SSH tunnel..."
ps aux | grep '[s]sh -N -L.*9090' | grep -v grep

echo -e "\nCleaning up existing gateway SSH tunnel..."
ps aux | grep '[s]sh -N -L.*9090' | grep -v grep | awk '{print $2}' | xargs -r kill -9
if [ $? -eq 0 ]; then
  echo "Successfully killed SSH tunnel process"
else
  echo "No gateway SSH tunnel process found"
fi

# Also check for processes using port 9090 directly
if command -v lsof &> /dev/null; then
  PID=$(lsof -ti:9090 2>/dev/null || true)
  if [ -n "$PID" ]; then
    echo "Found process using port 9090 (PID: $PID)"
    echo "Killing process $PID..."
    kill -9 "$PID" 2>/dev/null || true
  fi
elif command -v fuser &> /dev/null; then
  if fuser -n tcp 9090 &>/dev/null; then
    echo "Found process using port 9090"
    echo "Killing process..."
    fuser -k -n tcp 9090 2>/dev/null || true
  fi
fi

sleep 2

echo -e "\nVerifying cleanup..."
ps aux | grep '[s]sh -N -L.*9090' | grep -v grep

echo -e "\nStarting SSH tunnel to gl3 for gateway access..."
echo "This will forward port 9090 from your local machine to gl3"
echo ""
echo "Make sure you have run gateway-tunnel.sh or gateway-tunnel-standalone-python.sh on gl3 first!"
echo ""

# Use SSH config (gl3 uses ProxyJump glgate automatically)
# If SSH config is not set up, use: ssh -J glgate@145.108.225.3:42224 -N -L 9090:localhost:9090 ira340@gl3
ssh -N \
    -L 9090:localhost:9090 \
    gl3 &

TUNNEL_PID=$!
echo "SSH tunnel started with PID: $TUNNEL_PID"
echo ""
echo "You can now access the muBench application at:"
echo "  http://localhost:9090/s0"
echo ""
echo "Test with: curl -v http://localhost:9090/s0"
echo ""
echo "Press Ctrl+C to stop the tunnel."
echo "To stop manually: kill $TUNNEL_PID"

# Wait for the tunnel process
wait $TUNNEL_PID




