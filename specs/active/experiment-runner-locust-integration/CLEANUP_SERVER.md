# Server Cleanup Guide

## Quick Cleanup (Recommended)

**Before running a new experiment for testing, run:**
```bash
ssh gl3 "cd ~/muBench && ./scripts/cleanup-experiments.sh --all"
```

This cleans up all old experiment files, workspace directories, and Kubernetes namespaces.

## Files to Clean Up

After running experiments, these files/directories accumulate on the server:

1. **Experiment config files**: `~/muBench/experiments/mubench-*/K8sParameters.json`
2. **Simulation workspace**: `~/muBench/SimulationWorkspace/mubench-*/`
3. **Kubernetes namespaces**: All `mubench-*` namespaces

## Cleanup Commands

### Option 1: Clean Everything (Recommended for Fresh Start)

```bash
# On server (via SSH)
ssh gl3 << 'EOF'
# 1. Remove all experiment config directories
rm -rf ~/muBench/experiments/mubench-*

# 2. Remove all simulation workspace directories
rm -rf ~/muBench/SimulationWorkspace/mubench-*

# 3. Delete all mubench namespaces
kubectl get namespaces -o name | grep '^namespace/mubench-' | xargs -r kubectl delete

echo "✓ Cleanup complete"
EOF
```

### Option 2: Clean Specific Topology/Size

```bash
# Clean specific topology+size (e.g., sequential_fanout, size 5)
ssh gl3 << 'EOF'
TOPOLOGY="sequential-fanout"
SIZE="5"
PATTERN="mubench-${TOPOLOGY}-${SIZE}-"

# Remove config files
rm -rf ~/muBench/experiments/${PATTERN}*

# Remove workspace
rm -rf ~/muBench/SimulationWorkspace/${PATTERN}*

# Delete namespaces
kubectl get namespaces -o name | grep ${PATTERN} | xargs -r kubectl delete

echo "✓ Cleaned ${PATTERN}*"
EOF
```

### Option 3: Check Before Cleaning

```bash
# See what will be cleaned
ssh gl3 << 'EOF'
echo "=== Experiment Config Files ==="
find ~/muBench/experiments -name 'K8sParameters.json' 2>/dev/null | wc -l
echo "files found"

echo -e "\n=== Simulation Workspace Directories ==="
find ~/muBench/SimulationWorkspace -type d -name 'mubench-*' 2>/dev/null | wc -l
echo "directories found"

echo -e "\n=== Kubernetes Namespaces ==="
kubectl get namespaces | grep '^mubench-' | wc -l
echo "namespaces found"

echo -e "\n=== List All ==="
echo "Config files:"
find ~/muBench/experiments -name 'K8sParameters.json' 2>/dev/null | head -10

echo -e "\nWorkspace dirs:"
find ~/muBench/SimulationWorkspace -type d -name 'mubench-*' 2>/dev/null | head -10

echo -e "\nNamespaces:"
kubectl get namespaces | grep '^mubench-'
EOF
```

## Quick Cleanup (Copy-Paste)

**Full cleanup:**
```bash
ssh gl3 "rm -rf ~/muBench/experiments/mubench-* ~/muBench/SimulationWorkspace/mubench-* && kubectl get namespaces -o name | grep '^namespace/mubench-' | xargs -r kubectl delete && echo '✓ Cleanup complete'"
```

**Check what exists:**
```bash
ssh gl3 "echo 'Config files:' && find ~/muBench/experiments -name 'K8sParameters.json' 2>/dev/null | wc -l && echo 'Workspace dirs:' && find ~/muBench/SimulationWorkspace -type d -name 'mubench-*' 2>/dev/null | wc -l && echo 'Namespaces:' && kubectl get namespaces | grep '^mubench-' | wc -l"
```

## What Gets Created Per Run

Each experiment run creates:
- **Config file**: `~/muBench/experiments/{namespace}/K8sParameters.json`
- **Workspace**: `~/muBench/SimulationWorkspace/{namespace}/` (contains YAML files, logs, etc.)
- **Kubernetes namespace**: `{namespace}` (contains all pods, services, configmaps)

## When to Clean Up

- **Before starting fresh experiments**: Clean everything
- **After testing**: Clean test namespaces
- **Periodically**: Clean old namespaces to free resources

