#!/bin/bash

BATCH_SIZE=200
CONTAINER_ID="5d7cd5cc1341"
YAML_DIR="/root/muBench/SimulationWorkspace/yamls"

# Debug: Check if container exists
echo "Checking container..."
docker ps | grep $CONTAINER_ID

# Debug: Check if directory exists in container
echo "Checking directory in container..."
docker exec $CONTAINER_ID ls -l $YAML_DIR

# Get list of deployment YAML files
echo "Getting list of deployment YAML files..."
YAML_LIST=($(docker exec $CONTAINER_ID bash -c "ls $YAML_DIR/MicroServiceDeployment-*-Deployment-*.yaml | grep -v 'ConfigMap\|NginxGw'"))
TOTAL=${#YAML_LIST[@]}

# Debug: Show what files were found
echo "Found YAML files:"
printf '%s\n' "${YAML_LIST[@]}"

# Count system pods (they're always running)
SYSTEM_PODS=$(kubectl get pods -n kube-system | grep -v "NAME" | wc -l)

echo "Total deployments to process: $TOTAL"
echo "Batch size: $BATCH_SIZE"
echo "Number of batches: $(( (TOTAL + BATCH_SIZE - 1) / BATCH_SIZE ))"
echo "System pods count: $SYSTEM_PODS"
echo "----------------------------------------"

for ((i=0; i<$TOTAL; i+=$BATCH_SIZE)); do
    BATCH_START_TIME=$(date +%s)
    echo "----------------------------------------"
    echo "Starting batch $((i/BATCH_SIZE+1)) at $(date)"
    echo "Deploying pods $i to $((i+BATCH_SIZE-1)) of $TOTAL"
    
    # Apply the current batch
    echo "Applying deployments..."
    for ((j=i; j<i+BATCH_SIZE && j<TOTAL; j++)); do
        # Copy the YAML file from container to a temporary location
        TEMP_YAML=$(mktemp)
        docker exec $CONTAINER_ID cat "${YAML_LIST[$j]}" > "$TEMP_YAML"
        
        if ! kubectl apply -f "$TEMP_YAML"; then
            echo "Error: Failed to apply ${YAML_LIST[$j]}"
            rm "$TEMP_YAML"
            exit 1
        fi
        rm "$TEMP_YAML"
    done

    # Wait for all pods in this batch to be running or completed
    echo "Waiting for pods to be ready..."
    WAIT_START_TIME=$(date +%s)
    while true; do
        # Get current time for timeout check
        CURRENT_TIME=$(date +%s)
        WAIT_DURATION=$((CURRENT_TIME - WAIT_START_TIME))
        
        # Timeout after 10 minutes
        if [ $WAIT_DURATION -gt 600 ]; then
            echo "Warning: Timeout reached after 10 minutes. Some pods may not be ready."
            break
        fi
        
        # Get all pods except system pods
        NOT_READY=$(kubectl get pods | grep -v "NAME" | grep -v "Running\|Completed" | wc -l)
        RUNNING=$(kubectl get pods | grep -v "NAME" | grep "Running" | wc -l)
        
        if [ "$NOT_READY" -eq 0 ]; then  # No pods not ready
            break
        fi
        
        echo "[$(date)] Status: $NOT_READY pods not ready, $RUNNING pods running (batch $((i/BATCH_SIZE+1)))"
        sleep 15
    done
    
    BATCH_END_TIME=$(date +%s)
    BATCH_DURATION=$((BATCH_END_TIME - BATCH_START_TIME))
    echo "Batch $((i/BATCH_SIZE+1)) complete in $BATCH_DURATION seconds"
    echo "----------------------------------------"
done

echo "All deployments applied!"
