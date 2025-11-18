# Step-by-Step Testing Guide

**Purpose**: Test the deployment integration implementation incrementally to catch issues early.

## Prerequisites Check

Before starting, verify these are set up:

**On Host Machine:**
- [ ] Experiment Runner installed and working
- [ ] Python dependencies installed (`requests` module)
- [ ] SSH access to gl3 server works: `ssh gl3`
- [ ] kubectl installed (if using local kubectl, not SSH)

**On Server (gl3):**
- [ ] minikube running: `kubectl get nodes`
- [ ] Prometheus deployed: `kubectl get svc -n monitoring prometheus-nodeport`
- [ ] All 18 workmodel files exist in `Examples/` directory

## Test 1: Syntax and Import Check

**Goal**: Verify the code loads without syntax errors.

**Steps:**
```bash
# On host machine
cd ~/Documents/Research\ Project/experiment-runner
source venv/bin/activate  # If using venv
python -c "from examples.mubench_benchmarking.RunnerConfig import RunnerConfig; print('✓ Imports OK')"
```

**Expected**: No errors, prints "✓ Imports OK"

**If errors occur:**
- Check Python version (needs 3.7+)
- Check if `requests` module is installed: `pip install requests`
- Check if Experiment Runner dependencies are installed

---

## Test 2: Workmodel Mapping Function

**Goal**: Verify all 18 topology+size combinations map to correct workmodel files.

**Steps:**
```bash
# On host machine
cd ~/Documents/Research\ Project/experiment-runner
python3 << 'EOF'
import sys
sys.path.insert(0, '.')
from examples.mubench_benchmarking.RunnerConfig import RunnerConfig

config = RunnerConfig()

# Test all 18 combinations
topologies = ["sequential_fanout", "parallel_fanout", "centralized_star", 
              "hierarchical_tree", "probabilistic_tree", "complex_mesh"]
sizes = [5, 10, 20]

print("Testing workmodel mapping...")
errors = []
for topology in topologies:
    for size in sizes:
        try:
            path = config.get_workmodel_path(topology, size)
            exists = path.exists()
            status = "✓" if exists else "✗ MISSING"
            print(f"  {status} {topology} + {size} → {path.name}")
            if not exists:
                errors.append(f"{topology}+{size}: {path}")
        except Exception as e:
            print(f"  ✗ ERROR {topology} + {size}: {e}")
            errors.append(f"{topology}+{size}: {e}")

if errors:
    print(f"\n✗ Found {len(errors)} errors:")
    for e in errors:
        print(f"  - {e}")
else:
    print("\n✓ All 18 workmodel mappings verified!")
EOF
```

**Expected**: All 18 combinations map correctly and files exist

**If errors occur:**
- Check if workmodel files exist in `muBench/Examples/`
- Verify file naming matches the mapping
- Check path resolution (muBench should be sibling to experiment-runner)

---

## Test 3: K8sParameters Generation

**Goal**: Verify K8sParameters.json generation works correctly.

**Steps:**
```bash
# On host machine
cd ~/Documents/Research\ Project/experiment-runner
python3 << 'EOF'
import sys
import json
from pathlib import Path
sys.path.insert(0, '.')
from examples.mubench_benchmarking.RunnerConfig import RunnerConfig

config = RunnerConfig()

# Test with one topology+size
topology = "sequential_fanout"
size = 5
namespace = "mubench-test-namespace"

# Get workmodel path
workmodel_path = config.get_workmodel_path(topology, size)
print(f"Workmodel: {workmodel_path.name}")

# Create test output directory
test_dir = Path("/tmp/test_k8s_params")
test_dir.mkdir(exist_ok=True)

# Generate K8sParameters
try:
    k8s_params_file = config.generate_k8s_parameters(
        namespace=namespace,
        workmodel_path=workmodel_path,
        output_dir=test_dir
    )
    print(f"✓ Generated: {k8s_params_file}")
    
    # Verify contents
    with open(k8s_params_file, 'r') as f:
        params = json.load(f)
    
    print(f"  Namespace: {params['K8sParameters']['namespace']}")
    print(f"  WorkModelPath: {params['WorkModelPath']}")
    print(f"  OutputPath: {params['OutputPath']}")
    
    # Verify values
    assert params['K8sParameters']['namespace'] == namespace, "Namespace mismatch"
    assert 'WorkModelPath' in params, "WorkModelPath missing"
    assert 'OutputPath' in params, "OutputPath missing"
    
    print("\n✓ K8sParameters generation verified!")
    
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
```

**Expected**: K8sParameters.json generated with correct values

**If errors occur:**
- Check if `Configs/K8sParameters.json` template exists
- Verify JSON structure matches expected format
- Check file permissions

---

## Test 4: Namespace Management (if kubectl available)

**Goal**: Verify namespace creation/deletion works (if kubectl context is set).

**Steps:**
```bash
# First, check if kubectl is available and context is set
kubectl config current-context
kubectl get nodes

# If kubectl works, test namespace functions
cd ~/Documents/Research\ Project/experiment-runner
python3 << 'EOF'
import sys
sys.path.insert(0, '.')
from examples.mubench_benchmarking.RunnerConfig import RunnerConfig

config = RunnerConfig()

# Test namespace creation
test_namespace = "mubench-test-namespace-12345"
print(f"Testing namespace creation: {test_namespace}")

try:
    # Create namespace
    result = config.create_namespace(test_namespace)
    if result:
        print("✓ Namespace created successfully")
    else:
        print("✗ Namespace creation failed")
    
    # Try to create again (should detect existing)
    result2 = config.create_namespace(test_namespace)
    if result2:
        print("✓ Detected existing namespace correctly")
    
    # Delete namespace
    result3 = config.delete_namespace(test_namespace)
    if result3:
        print("✓ Namespace deleted successfully")
    else:
        print("✗ Namespace deletion failed")
    
    print("\n✓ Namespace management verified!")
    
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
```

**Expected**: Namespace created, detected, and deleted successfully

**If errors occur:**
- Check kubectl is installed: `which kubectl`
- Check kubectl context: `kubectl config current-context`
- If kubectl context not set, we'll need to use SSH option (see Test 5)

---

## Test 5: Verify Server Setup

**Goal**: Verify server has everything needed for deployment.

**Steps:**
```bash
# SSH to server
ssh gl3

# Check minikube
kubectl get nodes

# Check Prometheus
kubectl get svc -n monitoring prometheus-nodeport

# Check workmodel files
ls -la /root/muBench/Examples/workmodel-*.json | wc -l
# Should show 18+ files

# Check K8sDeployer exists
ls -la /root/muBench/Deployers/K8sDeployer/RunK8sDeployer.py

# Exit server
exit
```

**Expected**: All checks pass

**If errors occur:**
- Start minikube: `minikube start`
- Deploy Prometheus: See `Monitoring/kubernetes-full-monitoring/README.md`
- Verify workmodel files exist

---

## Test 6: Manual Deployment Test (on Server)

**Goal**: Test manual deployment to verify K8sDeployer works.

**Steps:**
```bash
# On server
ssh gl3
cd /root/muBench

# Test with one workmodel
python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json

# Wait for pods
kubectl get pods -n default
kubectl wait --for=condition=ready pod --all -n default --timeout=300s

# Check gateway service
kubectl get svc gw-nginx -n default

# Clean up
# (K8sDeployer will ask if you want to undeploy - say yes, or manually delete)
exit
```

**Expected**: Deployment succeeds, pods become ready, gateway service exists

**If errors occur:**
- Check minikube resources: `kubectl top nodes`
- Check pod logs: `kubectl logs <pod-name> -n <namespace>`
- Verify workmodel file is valid JSON

---

## Test 7: SSH Tunnel Setup

**Goal**: Verify SSH tunnels work for gateway and Prometheus access.

**Steps:**

**On Server (gl3):**
```bash
ssh gl3
cd /root/muBench

# Start port-forwards (use a test namespace, e.g., "default")
./scripts/combined-tunnels-server.sh default

# Keep this running in a separate terminal or background
```

**On Host Machine:**
```bash
# In a new terminal
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh

# Keep this running, then in another terminal test connectivity:
curl http://localhost:9090/s0
curl http://localhost:30000/api/v1/status/config
```

**Expected**: Both curl commands succeed

**If errors occur:**
- Check SSH access: `ssh gl3` should work
- Check port-forwards on server: `ps aux | grep "kubectl port-forward"`
- Check SSH tunnels on host: `ps aux | grep "ssh -N -L"`
- Verify ports 9090 and 30000 are not in use locally

---

## Test 8: Prometheus Query Test

**Goal**: Verify Prometheus queries work from host via SSH tunnel.

**Steps:**
```bash
# Ensure tunnels are running (from Test 7)

# On host machine
cd ~/Documents/Research\ Project/experiment-runner
python3 << 'EOF'
import sys
sys.path.insert(0, '.')
from examples.mubench_benchmarking.RunnerConfig import RunnerConfig

config = RunnerConfig()

# Test Prometheus connectivity
print("Testing Prometheus connectivity...")
try:
    # Simple query
    data = config.query_prometheus("up")
    if data:
        print("✓ Prometheus query successful")
        print(f"  Results: {len(data.get('result', []))} metrics")
    else:
        print("✗ Prometheus query returned no data")
except Exception as e:
    print(f"✗ Prometheus query failed: {e}")
    import traceback
    traceback.print_exc()

# Test CPU query (use a namespace that exists, e.g., "default" or "monitoring")
print("\nTesting CPU usage query...")
try:
    cpu = config.get_cpu_usage("default")  # or "monitoring"
    if cpu is not None:
        print(f"✓ CPU usage query successful: {cpu:.4f}")
    else:
        print("⚠ CPU usage query returned None (may be normal if no pods in namespace)")
except Exception as e:
    print(f"✗ CPU usage query failed: {e}")

# Test memory query
print("\nTesting memory usage query...")
try:
    memory = config.get_memory_usage("default")
    if memory is not None:
        print(f"✓ Memory usage query successful: {memory / (1024**2):.2f} MB")
    else:
        print("⚠ Memory usage query returned None (may be normal if no pods in namespace)")
except Exception as e:
    print(f"✗ Memory usage query failed: {e}")
EOF
```

**Expected**: Prometheus queries succeed (may return None if no pods in namespace, which is OK)

**If errors occur:**
- Verify SSH tunnel is running: `ps aux | grep "ssh -N -L.*30000"`
- Test Prometheus directly: `curl http://localhost:30000/api/v1/query?query=up`
- Check Prometheus PodMonitor is deployed: `kubectl get podmonitor -n monitoring`

---

## Test 9: Single Run End-to-End (Minimal)

**Goal**: Test one complete run with actual deployment.

**Prerequisites:**
- All previous tests passed
- SSH tunnels running (gateway + Prometheus)
- Server port-forwards running

**Steps:**
```bash
# On host machine
cd ~/Documents/Research\ Project/experiment-runner

# Modify RunnerConfig.py temporarily for testing:
# - Set repetitions=1
# - Set LOCUST_DURATION="10s" (already set)
# - Set time_between_runs_in_ms=5000

# Run experiment
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
```

**Watch for:**
- Workmodel mapping works
- Namespace creation works
- K8sDeployer execution (may need to run via SSH if kubectl context not set)
- Pod readiness wait
- Gateway verification
- Locust execution
- Prometheus queries
- Metric parsing

**Expected**: One run completes successfully with all metrics populated

**If errors occur:**
- Check logs for specific error messages
- Verify each step individually
- Check namespace exists on server: `kubectl get namespaces | grep mubench`
- Check pods: `kubectl get pods -n <namespace>`

---

## Test 10: Multiple Runs Test

**Goal**: Verify namespace isolation and cleanup between runs.

**Steps:**
```bash
# On host machine
# Modify RunnerConfig.py:
# - Set repetitions=2 (or 3)
# - Keep LOCUST_DURATION="10s"

# Run experiment
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py

# After experiment, check namespaces on server
ssh gl3
kubectl get namespaces | grep mubench
# Should see multiple namespaces (one per run)
```

**Expected**: Multiple runs complete, each with its own namespace

**If errors occur:**
- Check if cleanup is interfering (disable cleanup for testing)
- Verify namespace naming is unique per run
- Check resource limits on minikube

---

## Troubleshooting Common Issues

### Issue: kubectl commands fail on host
**Solution**: Either:
- Set kubectl context to point to server: `kubectl config set-context <context>`
- Or modify code to use SSH: `ssh gl3 "kubectl ..."`

### Issue: K8sDeployer fails
**Solution**: 
- K8sDeployer must run on server where minikube is
- Either copy config to server and run there, or use SSH

### Issue: Gateway not accessible
**Solution**:
- Verify port-forward on server: `kubectl get pods -n <namespace> | grep gw-nginx`
- Verify SSH tunnel on host: `ps aux | grep "ssh -N -L.*9090"`
- Test directly: `curl http://localhost:9090/s0`

### Issue: Prometheus queries return None
**Solution**:
- Verify Prometheus PodMonitor is deployed: `kubectl get podmonitor -n monitoring`
- Check Prometheus is scraping: `curl http://localhost:30000/api/v1/targets`
- Verify namespace has pods with prometheus.io/scrape annotation

---

## Next Steps After Testing

Once all tests pass:
1. Scale up to more runs (e.g., 5-10 runs)
2. Increase Locust duration to realistic values (10 minutes)
3. Test with all 18 topology+size combinations
4. Test with full 30 repetitions (540 runs total)


