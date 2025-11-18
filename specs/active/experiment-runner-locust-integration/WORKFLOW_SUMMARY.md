# Experiment Runner Workflow Summary

## Per-Run Workflow (18 runs total)

For each run, the Experiment Runner executes the following sequence:

### 1. **Deploy muBench Topology** (`start_run` hook)
   - Map topology+size to workmodel file
   - Clean up any existing deployments for this topology+size
   - Create unique namespace: `mubench-{topology}-{size}-{replicate}`
   - Generate `K8sParameters.json` on server
   - Execute `K8sDeployer` via SSH to server
   - **Result**: All Kubernetes resources (pods, services, configmaps) created

### 2. **Wait for All Pods to be Running** (`start_run` hook, step 6)
   - Execute: `kubectl wait --for=condition=ready pod --all -n {namespace} --timeout=300s`
   - **Result**: All pods are ready and running

### 3. **Setup Gateway Port-Forward** (`start_run` hook, step 7)
   - Verify `gw-nginx` service exists (with retry if needed)
   - Kill any existing gateway port-forward
   - Start new port-forward: `kubectl port-forward svc/gw-nginx 9090:80 -n {namespace}`
   - Verify gateway accessibility via SSH tunnel
   - **Result**: Gateway accessible at `http://localhost:9090` on host

### 4. **Send Workload (Locust)** (`interact` hook)
   - Execute Locust in headless mode:
     ```bash
     locust -f locustfile.py --headless \
       -u {users} -r {spawn_rate} -t {duration} \
       --host http://localhost:9090 \
       --csv {output_dir}/results \
       StochasticBenchmarkUser
     ```
   - **Result**: Load generated, metrics collected in CSV files

### 5. **Get Metrics (Prometheus)** (`stop_measurement` hook)
   - Query Prometheus for CPU usage: `avg(rate(container_cpu_usage_seconds_total{namespace="{namespace}"}[5m]))`
   - Query Prometheus for memory usage: `avg(container_memory_usage_bytes{namespace="{namespace}"})`
   - Save metrics to files in run directory
   - **Result**: CPU and memory metrics collected

### 6. **Parse and Save Metrics** (`populate_run_data` hook)
   - Parse Locust CSV: `results_stats.csv` → extract RPS, latency
   - Parse Prometheus files: extract CPU and memory values
   - Update `run_table.csv` with all metrics
   - **Result**: All metrics in structured format

### 7. **Move to Next Topology**
   - Experiment Runner automatically moves to next run
   - Namespace cleanup (optional, currently disabled for debugging)
   - Process repeats for next topology+size combination

## Current Status

✅ **All steps implemented and working:**
- Deployments completing successfully
- Pods becoming ready
- Gateway port-forward working (with service existence check)
- Locust executing and collecting metrics
- Prometheus queries working (after tunnel fix)
- Metrics being parsed and saved

⚠️ **Minor issues (non-blocking):**
- "gw-nginx" service not found error: Fixed with service existence check and retry
- Locust exit code 1: Expected if some requests fail, but metrics still collected

## Key Points

1. **Namespace Isolation**: Each run gets its own namespace, ensuring clean state
2. **Gateway Port-Forward**: Must be restarted per run (namespace changes)
3. **Prometheus Port-Forward**: Stays running (monitors all namespaces)
4. **SSH Tunnels**: Run once per experiment on host (`tunnels-local.sh`)
5. **Workload Timing**: Locust runs after all pods are ready and gateway is accessible

## Experiment Flow

```
For each of 18 runs (6 topologies × 3 sizes × 1 repetition):
  1. Deploy → 2. Wait for pods → 3. Setup gateway → 4. Run Locust → 5. Get Prometheus → 6. Parse metrics → Next run
```

**Total Time**: ~18 runs × (deploy time + 10s Locust + metrics) ≈ varies by deployment speed

