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

echo "Setting system limits for Istio..."
minikube ssh "sudo sysctl -w fs.file-max=1048576 && sudo sysctl -w fs.inotify.max_user_instances=1048576 && sudo sysctl -w fs.inotify.max_user_watches=1048576"

# echo "Installing monitoring..."
# docker exec -it mubench bash -c "cd Monitoring/kubernetes-full-monitoring && sh ./monitoring-install.sh"

# echo "Generating topology..."
# docker exec -it mubench bash -c "cd Configs && python3 topology_generator.py"

# echo "Generating work model..."
# docker exec -it mubench bash -c "python3 WorkModelGenerator/RunWorkModelGen.py -c Configs/WorkModelParameters.json"

echo "Deploying to Kubernetes..."
echo "y" | docker exec -i mubench bash -c "cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json"
docker exec -it mubench bash -c "cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json"

echo "Starting monitoring loop (press Ctrl+C to stop)..."
echo "When all pods are running, run: python3 Benchmarks/Runner/Runner.py -c Configs/RunnerParameters.json"
while true; do
    echo -e "\n=== $(date) ==="
    echo "Pod status by state:"
    kubectl get pods --all-namespaces --no-headers | awk '{print $4}' | sort | uniq -c
    echo -e "\nRecent events:"
    echo "kubectl get events --sort-by='.lastTimestamp' | cat"
    echo -e "\nWaiting 15 seconds before next check..."
    sleep 15
done