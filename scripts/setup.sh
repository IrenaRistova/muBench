#!/bin/bash

echo "Setting up minikube configuration..."
minikube config set memory 358400  # 350GB in MB (leaving some RAM for host system)
minikube config set cpus 28        # 28 vCPUs (leaving 4 for host system)
minikube config set disk-size 1024000  # 1TB in MB (we can increase this if needed)

echo "Starting minikube..."
minikube start \
  --cpus=28 \
  --memory=358400 \
  --disk-size=1024000 \
  --extra-config=kubelet.max-pods=1500 \
  --driver=docker \
  --container-runtime=containerd \
  --network-plugin=cni \
  --extra-config=kubelet.reserved-cpus=0,1,2,3 \
  --extra-config=kubelet.reserved-memory=0:memory=4Gi \
  --extra-config=kubelet.cpu-manager-policy=static \
  --extra-config=kubelet.topology-manager-policy=single-numa-node

echo "Starting mubench container..."
# Get the absolute path to muBench root (parent of scripts directory)
MUBENCH_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
docker run -d --name mubench --network minikube -v "${MUBENCH_ROOT}:/root/muBench" msvcbench/mubench

echo "Copying kubectl config..."
minikube kubectl -- config view --flatten > config
docker cp config mubench:/root/.kube/config

# echo "Setting system limits for Istio..."
# minikube ssh "sudo sysctl -w fs.file-max=1048576 && sudo sysctl -w fs.inotify.max_user_instances=1048576 && sudo sysctl -w fs.inotify.max_user_watches=1048576"

echo "Installing Prometheus (Prometheus-only, no Grafana/Jaeger/Kiali/Istio)..."
docker exec mubench bash -c "cd /root/muBench/Monitoring/kubernetes-full-monitoring && bash ./prometheus-only-install.sh"

# echo "Generating topology..."
# docker exec -it mubench bash -c "cd Configs && python3 topology_generator.py"

# echo "Generating work model..."
# docker exec -it mubench bash -c "python3 WorkModelGenerator/RunWorkModelGen.py -c Configs/WorkModelParameters.json"

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps to run experiments:"
echo ""
echo "ON SERVER:"
echo ""
echo "1. Update workmodel (if needed):"
echo "   Edit Configs/K8sParameters.json to change WorkModelPath"
echo ""
echo "2. Deploy muBench application:"
echo "   docker exec mubench bash -c \"cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json\""
echo ""
echo "3. Start gateway port-forward (keep running):"
echo "   ./scripts/start-mubench-gateway-tunnel.sh"
echo ""
echo "4. Verify deployment (in another terminal):"
echo "   ./scripts/verify-deployment.sh default http://localhost:9090"
echo ""
echo "5. Monitor baseline CPU (optional):"
echo "   ./scripts/run-sar-on-server.sh 100 1"
echo ""
echo "ON HOST MACHINE:"
echo ""
echo "6. Start SSH tunnel (keep running):"
echo "   ./scripts/gateway-tunnel-local.sh"
echo ""
echo "7. Run experiment:"
echo "   python3 Benchmarks/Runner/Runner.py -c Configs/RunnerParameters-external.json"
echo "   OR"
echo "   cd experiment-runner/examples/mubench-benchmarking && python3 Runner.py"
echo ""
echo "See scripts/WORKFLOW_GUIDE.md for complete workflow documentation"
echo ""
echo "=========================================="
echo ""
echo "NOTE: This script now deploys an initial muBench application."
echo "For Experiment Runner integration, use setup-infrastructure.sh instead,"
echo "which sets up minikube + Prometheus WITHOUT deploying a workmodel."
echo ""
echo "Deploying initial muBench application..."
echo "y" | docker exec -i mubench bash -c "cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json" || true
echo ""
echo "Initial deployment complete. Follow the steps above to run experiments."