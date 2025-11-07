#!/bin/bash

# Script to set up port forwarding for the nginx gateway service
# This allows accessing the muBench application from the server

echo "Checking existing gateway port forwards..."
ps aux | grep "kubectl port-forward.*gw-nginx" | grep -v grep

# Kill any existing gateway port forwarding
echo -e "\nCleaning up existing gateway port forwards..."
pkill -f "kubectl port-forward.*gw-nginx" || true

PIDS=$(ps aux | grep '[k]ubectl port-forward.*gw-nginx' | awk '{print $2}')
if [ -n "$PIDS" ]; then
  echo "Force killing kubectl port-forward PIDs: $PIDS"
  kill -9 $PIDS
else
  echo "No gateway port-forward processes found."
fi

# Kill any process using port 9090
if fuser -n tcp 9090 &>/dev/null; then
  echo "Killing process using port 9090"
  fuser -k -n tcp 9090
fi
sleep 2

# Start port forwarding for gateway
echo -e "\nStarting port forwarding for nginx gateway..."
kubectl port-forward svc/gw-nginx 9090:80 &
GATEWAY_PID=$!

echo "Gateway port forwarding started with PID: $GATEWAY_PID"
echo ""
echo "Gateway is now accessible at: http://localhost:9090"
echo ""
echo "On your local machine, set up SSH tunnel with:"
echo "ssh -J glgate@145.108.225.3:42224 -N -L 9090:localhost:9090 ira340@gl3"
echo ""
echo "Then you can test the application with:"
echo "curl -v http://localhost:9090/s0"
echo ""
echo "Press Ctrl+C to stop port forwarding."
wait





