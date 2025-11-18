# Deployment Workflow: One-Time Setup vs Per-Run Operations

## Overview

The workflow is split into:
1. **One-Time Setup** (run once): minikube + Prometheus installation
2. **Per-Experiment Setup** (run once per experiment session): SSH tunnels
3. **Per-Run Operations** (automated by Experiment Runner): Deploy topology, update port-forwards, run tests

## Phase 1: One-Time Setup (Server - Run Once)

**When**: First time setup, or when minikube/Prometheus need to be reset

**Location**: On server (gl3)

**Script**: `muBench/scripts/setup-infrastructure.sh` (recommended for Experiment Runner)

**What it does**:
1. Configures minikube (memory, CPUs, disk)
2. Starts minikube cluster
3. Starts mubench Docker container
4. Copies kubectl config to container
5. Installs Prometheus (Prometheus-only, no Grafana/Jaeger/Kiali)
6. Deploys muBench PodMonitor for Prometheus scraping
7. **Does NOT deploy any workmodel** (deployment handled by Experiment Runner)

**Commands**:
```bash
# On server (gl3)
cd /root/muBench
./scripts/setup-infrastructure.sh
```

**Alternative**: `muBench/scripts/setup.sh` (includes initial workmodel deployment - not needed for Experiment Runner)

**After setup**:
- minikube running
- mubench container running
- Prometheus installed in `monitoring` namespace
- Prometheus accessible via NodePort (port 30000)
- muBench PodMonitor deployed

**Note**: This setup is **persistent** - you don't need to run it again unless you restart minikube or need to reinstall Prometheus.

---

## Phase 2: Per-Experiment Setup (Host - Run Once Per Experiment Session)

**When**: Before starting an experiment run (540 runs)

**Location**: On host machine

**What to do**:
1. Start Prometheus port-forward on server (one-time, stays running)
   - **Note**: Gateway port-forward cannot be started here (gateway service doesn't exist until after deployment)
   - Gateway port-forward will be started by Experiment Runner after each deployment
2. Start SSH tunnels on host (one-time, stays running)

### Step 2.1: Start Prometheus Port-Forward (Server)

**Location**: On server (gl3)

**IMPORTANT**: Gateway service (`gw-nginx`) doesn't exist until after a muBench deployment. Since `setup-infrastructure.sh` doesn't deploy anything, we can only start Prometheus port-forward at this stage. Gateway port-forward will be started by Experiment Runner after each deployment.

**Option A: Use Script (Recommended)**
```bash
# On server (gl3)
cd /root/muBench
./scripts/start-prometheus-port-forward.sh
# OR if running from mubench container:
# docker exec mubench bash -c "cd /root/muBench && ./scripts/start-prometheus-port-forward.sh"
```

**Option B: Manual Command**
```bash
# On server (gl3)
# Start Prometheus port-forward (stays running for all runs)
kubectl -n monitoring port-forward svc/prometheus-nodeport 30000:9090 &
```

**Note**: 
- Prometheus port-forward stays running for the entire experiment (all 540 runs). Prometheus namespace never changes.
- Gateway port-forward will be started by Experiment Runner in the `start_run` hook after each deployment (namespace changes per run).
- Gateway service doesn't exist until after deployment, so we can't start gateway port-forward during per-experiment setup.

### Step 2.2: Start SSH Tunnels (Host)

**Location**: On host machine

**Command**:
```bash
# On host machine
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh
```

**What it does**:
- Starts SSH tunnel for gateway: `ssh -L 9090:localhost:9090 gl3`
- Starts SSH tunnel for Prometheus: `ssh -L 30000:localhost:30000 gl3`

**Note**: These tunnels stay running for the entire experiment. They tunnel to whatever is listening on those ports on the server.

---

## Phase 3: Per-Run Operations (Automated by Experiment Runner)

**When**: For each of the 540 runs

**Location**: Automated by Experiment Runner on host

**What happens** (in `start_run` hook):

### 3.1: Cleanup Previous Deployment
- **Action**: Delete all namespaces matching `mubench-{topology}-{size}-*` (except current replicate)
- **Why**: Ensure clean state before deploying new topology
- **Command**: `kubectl delete namespace <namespace>` (via SSH or local kubectl)

### 3.2: Deploy New Topology
- **Action**: 
  1. Create namespace: `mubench-{topology}-{size}-{replicate}`
  2. Generate K8sParameters.json with correct workmodel path
  3. Execute K8sDeployer to deploy muBench application
  4. Wait for pods ready
- **Commands**:
  - `kubectl create namespace <namespace>`
  - `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c <config>`
  - `kubectl wait --for=condition=ready pod --all -n <namespace>`

### 3.3: Start Gateway Port-Forward (Server)
- **Action**: Start port-forward for gateway service in the new namespace
- **Why**: Gateway namespace changes per run, so port-forward needs to be updated
- **Command**: `kubectl port-forward svc/gw-nginx 9090:80 -n <namespace>`
- **Location**: Must run on server (via SSH or in `start_run` hook)

**Important**: The gateway port-forward needs to be **restarted for each run** because:
- Each run deploys to a different namespace
- The gateway service is in that namespace
- Port-forward must target the correct namespace

**Option A**: Restart port-forward in `start_run` hook (via SSH)
```python
# In start_run hook, after deployment:
subprocess.run([
    'ssh', 'gl3',
    f'pkill -f "kubectl port-forward.*gw-nginx" && '
    f'kubectl port-forward svc/gw-nginx 9090:80 -n {namespace} &'
], shell=True)
```

**Option B**: Use `combined-tunnels-server.sh` with namespace parameter
```python
# In start_run hook:
subprocess.run([
    'ssh', 'gl3',
    f'cd /root/muBench && ./scripts/combined-tunnels-server.sh {namespace}'
])
```

**Note**: Prometheus port-forward doesn't need to be restarted (always `monitoring` namespace).

### 3.4: Verify Gateway Accessibility
- **Action**: Test gateway via SSH tunnel
- **Command**: `curl http://localhost:9090/s0` (on host)
- **Location**: In `start_run` hook on host

### 3.5: Run Locust Workload
- **Action**: Execute Locust in `interact` hook
- **Location**: On host, accesses gateway via SSH tunnel

### 3.6: Query Prometheus Metrics
- **Action**: Query CPU and memory metrics in `stop_measurement` hook
- **Location**: On host, accesses Prometheus via SSH tunnel

### 3.7: Cleanup (Optional)
- **Action**: Delete namespace after run (optional, for debugging keep it)
- **Location**: In `stop_run` hook

---

## Complete Workflow Timeline

```
┌─────────────────────────────────────────────────────────────┐
│ ONE-TIME SETUP (Server)                                      │
│ ─────────────────────────────────────────────────────────── │
│ 1. Run setup-infrastructure.sh: minikube + Prometheus          │
│    (no workmodel deployment)                                  │
│    ✓ minikube running                                         │
│    ✓ Prometheus installed                                     │
│    ✓ muBench PodMonitor deployed                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ (Setup complete, persistent)
                          │
┌─────────────────────────────────────────────────────────────┐
│ PER-EXPERIMENT SETUP (Once per experiment session)          │
│ ─────────────────────────────────────────────────────────── │
│ SERVER:                                                      │
│ 2. Start Prometheus port-forward only                       │
│    ./scripts/start-prometheus-port-forward.sh               │
│    OR: kubectl -n monitoring port-forward ...              │
│    (Gateway port-forward started by Experiment Runner)     │                                              │
│                                                              │
│ HOST:                                                        │
│ 3. Start SSH tunnels (stays running)                        │
│    ./scripts/tunnels-local.sh                                │
│    ✓ Gateway tunnel: ssh -L 9090:localhost:9090 gl3         │
│    ✓ Prometheus tunnel: ssh -L 30000:localhost:30000 gl3   │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ (Tunnels running, persistent)
                          │
┌─────────────────────────────────────────────────────────────┐
│ PER-RUN OPERATIONS (Automated, 540 times)                    │
│ ─────────────────────────────────────────────────────────── │
│ For each run (topology + size + replicate):                 │
│                                                              │
│ 4. Cleanup previous deployment (same topology+size)          │
│    kubectl delete namespace mubench-{topology}-{size}-*     │
│                                                              │
│ 5. Deploy new topology                                       │
│    - Create namespace                                        │
│    - Generate K8sParameters.json                              │
│    - Run K8sDeployer                                         │
│    - Wait for pods ready                                     │
│                                                              │
│ 6. Start/Update gateway port-forward (SERVER)               │
│    kubectl port-forward svc/gw-nginx 9090:80 -n <namespace> │
│    (Kill old one, start new one for this namespace)         │
│                                                              │
│ 7. Verify gateway (HOST)                                     │
│    curl http://localhost:9090/s0                             │
│                                                              │
│ 8. Run Locust workload (HOST)                                │
│    locust --headless ... --host http://localhost:9090       │
│                                                              │
│ 9. Query Prometheus (HOST)                                   │
│    GET http://localhost:30000/api/v1/query?query=...         │
│                                                              │
│ 10. Parse metrics and store results                          │
│                                                              │
│ 11. Optional: Delete namespace (for cleanup)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Insights

### Gateway Port-Forward Management

**Problem**: Gateway namespace changes per run, but port-forward must target the correct namespace.

**Solution**: Restart gateway port-forward in `start_run` hook after deployment:

```python
# In start_run hook, after pods are ready:
# Kill existing gateway port-forward
subprocess.run(['ssh', 'gl3', 'pkill -f "kubectl port-forward.*gw-nginx"'])

# Start new port-forward for this namespace
subprocess.run([
    'ssh', 'gl3',
    f'kubectl port-forward svc/gw-nginx 9090:80 -n {namespace} &'
], shell=True)

# Wait a moment for port-forward to establish
time.sleep(2)
```

**Alternative**: Use `combined-tunnels-server.sh` which handles cleanup and restart:
```python
# In start_run hook:
subprocess.run([
    'ssh', 'gl3',
    f'cd /root/muBench && ./scripts/combined-tunnels-server.sh {namespace}'
])
```

### Prometheus Port-Forward

**No restart needed**: Prometheus is always in `monitoring` namespace, so port-forward can stay running for all runs.

### SSH Tunnels

**No restart needed**: SSH tunnels on host just forward `localhost:9090` and `localhost:30000` to server. They don't care what's listening on those ports - they just tunnel the traffic.

---

## Updated Implementation Plan

### Modify `start_run` Hook

Add gateway port-forward management:

```python
def start_run(self, context: RunnerContext) -> None:
    # ... existing deployment code ...
    
    # After pods are ready, start/update gateway port-forward
    output.console_log("  Starting gateway port-forward...")
    try:
        # Kill existing gateway port-forward (if any)
        subprocess.run(
            ['ssh', 'gl3', 'pkill -f "kubectl port-forward.*gw-nginx"'],
            capture_output=True,
            timeout=5
        )
        time.sleep(1)
        
        # Start new port-forward for this namespace
        # Run in background via SSH
        subprocess.Popen([
            'ssh', 'gl3',
            f'kubectl port-forward svc/gw-nginx 9090:80 -n {namespace}'
        ])
        
        # Wait for port-forward to establish
        time.sleep(3)
        
        output.console_log("  ✓ Gateway port-forward started")
    except Exception as e:
        output.console_log(f"  ⚠ Error starting port-forward: {e}")
        output.console_log("  Continuing anyway - ensure port-forward is running manually")
    
    # Verify gateway accessibility
    # ... existing verification code ...
```

### Or Use Combined Script

```python
# In start_run hook, after deployment:
output.console_log("  Starting port-forwards...")
try:
    # Use combined script which handles both gateway and Prometheus
    # It will restart gateway port-forward for new namespace
    result = subprocess.run([
        'ssh', 'gl3',
        f'cd /root/muBench && ./scripts/combined-tunnels-server.sh {namespace}'
    ], capture_output=True, text=True, timeout=30)
    
    if result.returncode == 0:
        output.console_log("  ✓ Port-forwards started")
    else:
        output.console_log(f"  ⚠ Port-forward script warning: {result.stderr}")
except Exception as e:
    output.console_log(f"  ⚠ Error: {e}")
    output.console_log("  Continuing anyway - ensure port-forwards are running")
```

---

## Testing Checklist

### Before Running Experiment

**On Server**:
- [ ] minikube running: `kubectl get nodes`
- [ ] Prometheus installed: `kubectl get pods -n monitoring`
- [ ] Prometheus port-forward running: `ps aux | grep "kubectl port-forward.*prometheus"`
- [ ] mubench container running: `docker ps | grep mubench`

**On Host**:
- [ ] SSH tunnels running: `ps aux | grep "ssh -N -L"`
- [ ] Gateway tunnel: `ssh -N -L 9090:localhost:9090 gl3`
- [ ] Prometheus tunnel: `ssh -N -L 30000:localhost:30000 gl3`
- [ ] Can access Prometheus: `curl http://localhost:30000/api/v1/status/config`

### During Experiment (Per Run)

**Automated by Experiment Runner**:
- [ ] Previous deployment cleaned up (same topology+size)
- [ ] Namespace created
- [ ] muBench application deployed
- [ ] Pods ready
- [ ] Gateway port-forward started/updated for new namespace
- [ ] Gateway accessible via SSH tunnel
- [ ] Locust workload executed
- [ ] Prometheus metrics queried
- [ ] Metrics parsed and stored

---

## Important Notes

1. **Gateway Port-Forward**: Must be restarted per run (namespace changes)
2. **Prometheus Port-Forward**: Stays running (namespace never changes)
3. **SSH Tunnels**: Stay running (just forward traffic)
4. **Cleanup**: Delete previous deployments for same topology+size before deploying new one
5. **K8sDeployer**: Must run on server (where minikube is)
6. **kubectl Commands**: May need to run via SSH if context not set on host

