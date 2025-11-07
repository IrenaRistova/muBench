#!/bin/bash

echo "Stopping all containers..."
docker stop $(docker ps -qa) 2>/dev/null || true

echo "Removing all containers..."
docker rm $(docker ps -qa) 2>/dev/null || true

echo "Removing all images..."
docker rmi -f $(docker images -qa) 2>/dev/null || true

echo "Removing all volumes..."
docker volume rm $(docker volume ls -qf dangling="true") 2>/dev/null || true

echo "Removing all networks..."
docker network rm $(docker network ls -q) 2>/dev/null || true

echo "Verifying cleanup..."

echo "Checking containers..."
docker ps -a

echo "Checking images..."
docker images -a

echo "Checking volumes..."
docker volume ls

echo "Checking networks..."
docker network ls

echo "Removing all minikube resources..."
minikube delete

echo "Cleanup complete!" 