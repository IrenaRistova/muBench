#!/bin/bash

echo "Checking existing SSH tunnels..."
ps aux | grep '[s]sh -N -L'

echo -e "\nCleaning up existing SSH tunnels..."
ps aux | grep '[s]sh -N -L' | awk '{print $2}' | xargs -r kill -9
if [ $? -eq 0 ]; then
  echo "Successfully killed SSH tunnel processes"
else
  echo "No SSH tunnel processes found or already killed"
fi
sleep 2

echo -e "\nVerifying cleanup..."
ps aux | grep '[s]sh -N -L'

echo -e "\nCleanup complete. You can now start new SSH tunnels." 

ssh -N -L 30000:localhost:30000 -L 30001:localhost:30001 -L 30002:localhost:30002 -L 30003:localhost:30003 gl5