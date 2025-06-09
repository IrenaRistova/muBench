#!/bin/bash

echo "Setting up minikube configuration..."
minikube config set memory 8192
minikube config set cpus 4

echo "Starting minikube..."
minikube start

echo "Starting mubench container..."
docker run -d --name mubench --network minikube -v "$(pwd):/root/muBench" msvcbench/mubench

echo "Copying kubectl config..."
minikube kubectl -- config view --flatten > config
docker cp config mubench:/root/.kube/config

echo "Installing monitoring..."
docker exec -it mubench bash -c "cd Monitoring/kubernetes-full-monitoring && sh ./monitoring-install.sh"

echo "Generating topology..."
docker exec -it mubench bash -c "cd Configs && python3 topology_generator.py"

echo "Generating work model..."
docker exec -it mubench bash -c "python3 WorkModelGenerator/RunWorkModelGen.py -c Configs/WorkModelParameters.json"

echo "Deploying to Kubernetes..."
echo "y" | docker exec -i mubench bash -c "python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json"
docker exec -it mubench bash -c "python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json"

echo "Check if all pods are running and then run python3 Benchmarks/Runner/Runner.py -c Configs/RunnerParameters.json after docker exec -it mubench bash" 