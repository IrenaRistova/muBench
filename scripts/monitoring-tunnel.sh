#!/bin/bash

# Check existing port forwards before cleanup
echo "Checking existing port forwards..."
ps aux | grep "kubectl port-forward" | grep -v grep

# Kill any existing port forwarding
echo -e "\nCleaning up existing port forwards..."
pkill -f "kubectl port-forward" || true
sleep 2

# Verify cleanup
echo -e "\nVerifying cleanup..."
ps aux | grep "kubectl port-forward" | grep -v grep

# Start port forwarding for all services
echo -e "\nStarting port forwarding for monitoring services..."
kubectl -n monitoring port-forward svc/prometheus-nodeport 30000:9090 &
kubectl -n monitoring port-forward svc/grafana-nodeport 30001:3000 &
kubectl -n istio-system port-forward svc/jaeger-nodeport 30002:80 &
kubectl -n istio-system port-forward svc/kiali-nodeport 30003:20001 &

echo -e "\nPort forwarding is now set up. On your local machine, run:"
echo "ssh -N -L 30000:localhost:30000 -L 30001:localhost:30001 -L 30002:localhost:30002 -L 30003:localhost:30003 gl5"

echo -e "\nThen you can access the monitoring tools at:"
echo "Prometheus: http://localhost:30000"
echo "Grafana: http://localhost:30001"
echo "Jaeger: http://localhost:30002"
echo "Kiali: http://localhost:30003"

echo -e "\nPress Ctrl+C to stop port forwarding."
wait
