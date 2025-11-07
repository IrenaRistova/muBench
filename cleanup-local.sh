#!/bin/bash

echo "Checking existing SSH tunnels..."
ps aux | grep "ssh.*-L" | grep -v grep

echo -e "\nCleaning up existing SSH tunnels..."
pkill -f "ssh.*-L" || true
sleep 2

echo -e "\nVerifying cleanup..."
ps aux | grep "ssh.*-L" | grep -v grep

echo -e "\nCleanup complete. You can now start new SSH tunnels." 

ssh -N -L 30000:localhost:30000 -L 30001:localhost:30001 -L 30002:localhost:30002 -L 30003:localhost:30003 gl5