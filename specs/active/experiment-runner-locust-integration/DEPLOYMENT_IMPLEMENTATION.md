# Deployment Implementation Guide

**Purpose**: Complete code snippets and implementation details for Phase 2 (Full Deployment Integration)

## Architecture Overview

### Host vs Server Distinction

**🔵 HOST MACHINE** (where Experiment Runner runs):
- **Location**: `~/Documents/Research Project/experiment-runner/`
- **Runs**: Experiment Runner, SSH tunnels
- **Accesses**: 
  - Gateway: `http://localhost:9090` (via SSH tunnel)
  - Prometheus: `http://localhost:30000` (via SSH tunnel)
- **Scripts**: `muBench/scripts/tunnels-local.sh` (SSH tunnels from host to server)

**🟢 SERVER (gl3)** (where minikube and muBench run):
- **Location**: Remote server (gl3)
- **Runs**: minikube, muBench deployments, Prometheus, kubectl port-forwards
- **Exposes**:
  - Gateway: `localhost:9090` (via kubectl port-forward)
  - Prometheus: `localhost:30000` (via kubectl port-forward)
- **Scripts**: `muBench/scripts/combined-tunnels-server.sh` (kubectl port-forwards on server)

### Connection Flow

```
┌─────────────────────────────────────────────────────────────┐
│ HOST MACHINE                                                │
│                                                             │
│  Experiment Runner                                          │
│  ├─ Accesses: http://localhost:9090 (Gateway)              │
│  └─ Accesses: http://localhost:30000 (Prometheus)          │
│                                                             │
│  SSH Tunnels (tunnels-local.sh)                            │
│  ├─ ssh -L 9090:localhost:9090 gl3                        │
│  └─ ssh -L 30000:localhost:30000 gl3                      │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ SSH Tunnel
                        │
┌─────────────────────────────────────────────────────────────┐
│ SERVER (gl3)                                                │
│                                                             │
│  kubectl Port-Forwards (combined-tunnels-server.sh)        │
│  ├─ kubectl port-forward svc/gw-nginx 9090:80 -n <ns>    │
│  └─ kubectl port-forward svc/prometheus-nodeport          │
│     30000:9090 -n monitoring                               │
│                                                             │
│  Kubernetes (minikube)                                      │
│  ├─ muBench deployments (per run namespace)                │
│  └─ Prometheus (monitoring namespace)                      │
└─────────────────────────────────────────────────────────────┘
```

### Setup Process

**Phase 1: One-Time Setup (Server)** - Run `setup-infrastructure.sh` once:
```bash
# On server (gl3) - RUN ONCE
cd /root/muBench
./scripts/setup-infrastructure.sh
# This sets up:
# - minikube cluster
# - mubench container
# - Prometheus installation
# - muBench PodMonitor
# Does NOT deploy any workmodel (deployment handled by Experiment Runner)
```

**Note**: The original `setup.sh` includes an initial workmodel deployment, which is not needed for Experiment Runner since it handles deployments per run.

**Phase 2: Per-Experiment Setup (Run once per experiment session)**:

**Step 2.1: On Server (gl3)** - Start Prometheus port-forward (stays running):
```bash
# On server (gl3) - RUN ONCE per experiment session
# Prometheus port-forward (stays running for all 540 runs)
cd /root/muBench
./scripts/start-prometheus-port-forward.sh
# OR manually:
# kubectl -n monitoring port-forward svc/prometheus-nodeport 30000:9090 &
```

**IMPORTANT**: Gateway service (`gw-nginx`) doesn't exist until after a muBench deployment. Since `setup-infrastructure.sh` doesn't deploy anything, we can only start Prometheus port-forward at this stage. Gateway port-forward will be started by Experiment Runner in the `start_run` hook after each deployment.

**Step 2.2: On Host Machine** - Start SSH tunnels (stays running):
```bash
# On host machine - RUN ONCE per experiment session
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh
# This sets up (stays running for all 540 runs):
# - ssh -L 9090:localhost:9090 gl3
# - ssh -L 30000:localhost:30000 gl3
```

**Phase 3: Per-Run Operations (Automated by Experiment Runner)**:

**For each run**, Experiment Runner will:
1. Clean up previous deployment (same topology+size)
2. Deploy new topology to new namespace
3. Wait for pods ready
4. **Start gateway port-forward** (namespace changes per run, gateway service now exists!)
5. Verify gateway accessibility
6. Run Locust workload
7. Query Prometheus metrics

**Important Notes**:
- **One-time setup**: minikube + Prometheus (run `setup-infrastructure.sh` once, no workmodel deployment)
- **Per-experiment setup**: Prometheus port-forward + SSH tunnels (run once per experiment)
- **Per-run**: Gateway port-forward must be restarted (namespace changes per run)
- Gateway namespace changes per run → port-forward must be updated
- Prometheus namespace is always `monitoring` → port-forward stays running
- SSH tunnels stay running (just forward traffic)

## Overview

This guide provides ready-to-use code snippets for implementing:
1. Workmodel mapping (topology+size → workmodel file)
2. Namespace management (create/delete per run)
3. K8sParameters.json generation
4. Deployment execution in `start_run` hook
5. Prometheus query functions
6. Prometheus parsing in `populate_run_data` hook
7. Cleanup in `stop_run` hook

## 1. Workmodel Mapping Function

**Location**: Add to `RunnerConfig` class

```python
def get_workmodel_path(self, topology: str, size: int) -> Path:
    """Map topology and size to workmodel file path.
    
    Args:
        topology: One of: sequential_fanout, parallel_fanout, centralized_star,
                  hierarchical_tree, probabilistic_tree, complex_mesh
        size: Number of services (5, 10, or 20)
    
    Returns:
        Path to workmodel JSON file
    """
    mapping = {
        "sequential_fanout": {
            5: "workmodel-serial-5services.json",
            10: "workmodel-serial-10services.json",
            20: "workmodel-serial-20services.json"
        },
        "parallel_fanout": {
            5: "workmodel-parallel-5services.json",
            10: "workmodel-parallel-10services.json",
            20: "workmodel-parallel-20services.json"
        },
        "centralized_star": {
            5: "workmodelA-5services.json",
            10: "workmodelA-10services.json",
            20: "workmodelA.json"
        },
        "hierarchical_tree": {
            5: "workmodelC-5services.json",
            10: "workmodelC-10services.json",
            20: "workmodelC.json"
        },
        "probabilistic_tree": {
            5: "workmodelC-multi-5services.json",
            10: "workmodelC-multi-10services.json",
            20: "workmodelC-multi.json"
        },
        "complex_mesh": {
            5: "workmodelD-5services.json",
            10: "workmodelD-10services.json",
            20: "workmodelD.json"
        }
    }
    
    if topology not in mapping:
        raise ValueError(f"Unknown topology: {topology}")
    if size not in mapping[topology]:
        raise ValueError(f"Unknown size for {topology}: {size}")
    
    workmodel_file = mapping[topology][size]
    workmodel_path = self.MUBENCH_DIR / 'Examples' / workmodel_file
    
    if not workmodel_path.exists():
        raise FileNotFoundError(f"Workmodel file not found: {workmodel_path}")
    
    return workmodel_path
```

## 2. Namespace Management Functions

**Location**: Add to `RunnerConfig` class

**Note**: These functions run on **HOST MACHINE** but execute `kubectl` commands that affect **SERVER**:
- kubectl commands connect to server's minikube cluster (ensure context is set)
- Or execute via SSH: `ssh gl3 "kubectl ..."`

```python
def create_namespace(self, namespace: str) -> bool:
    """Create Kubernetes namespace if it doesn't exist.
    
    NOTE: This runs on HOST but creates namespace on SERVER's minikube cluster.
    Ensure kubectl context points to server cluster, or use SSH option.
    
    Args:
        namespace: Namespace name
    
    Returns:
        True if created or already exists, False on error
    """
    try:
        # Option A: Use kubectl from host (if context is set to server)
        # Check if namespace exists
        result = subprocess.run(
            ['kubectl', 'get', 'namespace', namespace],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        # OR Option B: Execute via SSH
        # result = subprocess.run(
        #     ['ssh', 'gl3', f'kubectl get namespace {namespace}'],
        #     capture_output=True,
        #     text=True,
        #     timeout=10
        # )
        
        if result.returncode == 0:
            output.console_log(f"  Namespace '{namespace}' already exists")
            return True
        
        # Create namespace
        output.console_log(f"  Creating namespace '{namespace}'...")
        result = subprocess.run(
            ['kubectl', 'create', 'namespace', namespace],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        # OR via SSH:
        # result = subprocess.run(
        #     ['ssh', 'gl3', f'kubectl create namespace {namespace}'],
        #     capture_output=True,
        #     text=True,
        #     timeout=10
        # )
        
        if result.returncode == 0:
            output.console_log(f"  ✓ Namespace '{namespace}' created")
            return True
        else:
            output.console_log(f"  ✗ Failed to create namespace: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        output.console_log(f"  ✗ Timeout creating namespace '{namespace}'")
        return False
    except Exception as e:
        output.console_log(f"  ✗ Error creating namespace: {e}")
        return False

def delete_namespace(self, namespace: str) -> bool:
    """Delete Kubernetes namespace.
    
    NOTE: This runs on HOST but deletes namespace on SERVER's minikube cluster.
    Ensure kubectl context points to server cluster, or use SSH option.
    
    Args:
        namespace: Namespace name
    
    Returns:
        True if deleted successfully, False on error
    """
    try:
        output.console_log(f"  Deleting namespace '{namespace}'...")
        # Option A: Use kubectl from host (if context is set)
        result = subprocess.run(
            ['kubectl', 'delete', 'namespace', namespace],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # OR Option B: Execute via SSH
        # result = subprocess.run(
        #     ['ssh', 'gl3', f'kubectl delete namespace {namespace}'],
        #     capture_output=True,
        #     text=True,
        #     timeout=60
        # )
        
        if result.returncode == 0:
            output.console_log(f"  ✓ Namespace '{namespace}' deleted")
            return True
        else:
            output.console_log(f"  ✗ Failed to delete namespace: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        output.console_log(f"  ✗ Timeout deleting namespace '{namespace}'")
        return False
    except Exception as e:
        output.console_log(f"  ✗ Error deleting namespace: {e}")
        return False
```

## 3. K8sParameters.json Generation

**Location**: Add to `RunnerConfig` class

```python
def generate_k8s_parameters(self, namespace: str, workmodel_path: Path, output_dir: Path) -> Path:
    """Generate K8sParameters.json for a specific run.
    
    Args:
        namespace: Kubernetes namespace for this run
        workmodel_path: Path to workmodel JSON file (relative to muBench root)
        output_dir: Directory for run-specific output
    
    Returns:
        Path to generated K8sParameters.json file
    """
    # Load template
    with open(self.K8S_PARAMS_TEMPLATE, 'r') as f:
        config = json.load(f)
    
    # Update namespace
    config['K8sParameters']['namespace'] = namespace
    
    # Update workmodel path (relative to muBench root)
    # Convert absolute path to relative path from muBench root
    if workmodel_path.is_absolute():
        try:
            workmodel_path = workmodel_path.relative_to(self.MUBENCH_DIR)
        except ValueError:
            # If not relative to MUBENCH_DIR, use as-is
            pass
    config['WorkModelPath'] = str(workmodel_path)
    
    # Update output path (relative to muBench root)
    # Create run-specific output directory in muBench
    run_output_dir = self.MUBENCH_DIR / 'SimulationWorkspace' / namespace
    config['OutputPath'] = str(run_output_dir.relative_to(self.MUBENCH_DIR))
    
    # Save to run directory
    k8s_params_file = output_dir / 'K8sParameters.json'
    with open(k8s_params_file, 'w') as f:
        json.dump(config, f, indent=3)
    
    output.console_log(f"  Generated K8sParameters.json: {k8s_params_file}")
    return k8s_params_file
```

## 4. Deployment Execution

**Location**: Update `start_run` hook in `RunnerConfig.py`

**Note**: This runs on **HOST MACHINE** but executes commands that affect **SERVER**:
- `kubectl` commands execute via SSH to server (or assume kubectl context is set)
- K8sDeployer execution may need to run on server (via SSH) or use kubectl from host
- Gateway URL is `http://localhost:9090` (accessible via SSH tunnel from host)

```python
def start_run(self, context: RunnerContext) -> None:
    """Perform any activity required for starting the run here.
    For example, deploying muBench application."""
    
    topology = context.execute_run['topology']
    size = context.execute_run['system_size']
    replicate = context.run_nr
    
    output.console_log(f"Starting run: topology={topology}, size={size}, replicate={replicate}")
    
    # 1. Map topology+size to workmodel file
    try:
        workmodel_path = self.get_workmodel_path(topology, size)
        output.console_log(f"  Workmodel: {workmodel_path.name}")
    except Exception as e:
        output.console_log(f"  ✗ Failed to get workmodel path: {e}")
        raise
    
    # 2. Clean up any existing deployment for this topology+size combination
    # NOTE: Before deploying a new topology, we need to delete all pods from previous runs
    # This ensures clean state for each new deployment
    output.console_log("  Cleaning up any existing deployments for this topology+size...")
    # Find and delete any existing namespaces matching this topology+size pattern
    # (but not the current replicate number)
    cleanup_pattern = f"mubench-{topology}-{size}-"
    try:
        # Option A: Use kubectl from host
        list_cmd = ['kubectl', 'get', 'namespaces', '-o', 'name']
        result = subprocess.run(list_cmd, capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            for line in result.stdout.strip().split('\n'):
                if cleanup_pattern in line and f"-{replicate}" not in line:
                    existing_ns = line.replace('namespace/', '')
                    output.console_log(f"  Deleting existing namespace: {existing_ns}")
                    self.delete_namespace(existing_ns)
        
        # OR Option B: Execute via SSH
        # list_cmd = ['ssh', 'gl3', f'kubectl get namespaces -o name | grep "{cleanup_pattern}" | grep -v "-{replicate}"']
        # result = subprocess.run(list_cmd, shell=True, capture_output=True, text=True, timeout=10)
        # ... process result and delete namespaces
    except Exception as e:
        output.console_log(f"  ⚠ Error during cleanup: {e}")
        output.console_log("  Continuing anyway - may have existing deployments")
    
    # 3. Create namespace
    namespace = f"mubench-{topology}-{size}-{replicate}"
    if not self.create_namespace(namespace):
        raise RuntimeError(f"Failed to create namespace: {namespace}")
    
    # 4. Generate K8sParameters.json
    try:
        k8s_params_file = self.generate_k8s_parameters(
            namespace=namespace,
            workmodel_path=workmodel_path,
            output_dir=context.run_dir
        )
    except Exception as e:
        output.console_log(f"  ✗ Failed to generate K8sParameters: {e}")
        raise
    
    # 5. Execute K8sDeployer
    # NOTE: K8sDeployer must run on SERVER (where kubectl/minikube is)
    # Options:
    #   A) Run via SSH: ssh gl3 "cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c <config>"
    #   B) Use kubectl from host (if kubectl context points to server)
    #   C) Copy config to server and execute remotely
    output.console_log(f"  Deploying muBench application...")
    try:
        # Option A: Execute via SSH (recommended)
        # Copy config to server first, then execute
        deploy_cmd = [
            'ssh', 'gl3',
            f'cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c {k8s_params_file}'
        ]
        
        # OR Option B: Execute locally if kubectl context is set to server
        # deploy_cmd = [
        #     'python3',
        #     str(self.K8S_DEPLOYER),
        #     '-c', str(k8s_params_file)
        # ]
        
        result = subprocess.run(
            deploy_cmd,
            cwd=str(self.MUBENCH_DIR),
            capture_output=True,
            text=True,
            timeout=300  # 5 minutes timeout
        )
        
        if result.returncode != 0:
            output.console_log(f"  ✗ K8sDeployer failed: {result.stderr}")
            raise RuntimeError(f"K8sDeployer failed with exit code {result.returncode}")
        
        output.console_log("  ✓ K8sDeployer completed")
        
    except subprocess.TimeoutExpired:
        output.console_log("  ✗ K8sDeployer timed out")
        raise RuntimeError("K8sDeployer timed out")
    except Exception as e:
        output.console_log(f"  ✗ K8sDeployer error: {e}")
        raise
    
    # 6. Wait for pods to be ready
    # NOTE: kubectl command runs on HOST but connects to SERVER cluster
    # Ensure kubectl context is set to server's minikube cluster
    output.console_log(f"  Waiting for pods to be ready in namespace '{namespace}'...")
    try:
        # Option A: Use kubectl from host (if context is set)
        wait_cmd = [
            'kubectl', 'wait',
            '--for=condition=ready',
            'pod', '--all',
            '-n', namespace,
            '--timeout=300s'
        ]
        
        # OR Option B: Execute via SSH
        # wait_cmd = [
        #     'ssh', 'gl3',
        #     f'kubectl wait --for=condition=ready pod --all -n {namespace} --timeout=300s'
        # ]
        
        result = subprocess.run(
            wait_cmd,
            capture_output=True,
            text=True,
            timeout=320  # Slightly longer than kubectl timeout
        )
        
        if result.returncode == 0:
            output.console_log("  ✓ All pods ready")
        else:
            output.console_log(f"  ⚠ Some pods not ready: {result.stderr}")
            # Continue anyway - pods might be starting
            
    except subprocess.TimeoutExpired:
        output.console_log("  ⚠ Timeout waiting for pods (continuing anyway)")
    except Exception as e:
        output.console_log(f"  ⚠ Error waiting for pods: {e}")
    
        # 7. Start/Update gateway port-forward
        # IMPORTANT: Gateway port-forward must be restarted for each run because namespace changes
        # Prometheus port-forward stays running (always monitoring namespace)
        # Gateway port-forward must target the new namespace
        output.console_log("  Starting/updating gateway port-forward for this namespace...")
        try:
            # Kill existing gateway port-forward (if any)
            subprocess.run(
                ['ssh', 'gl3', 'pkill -f "kubectl port-forward.*gw-nginx"'],
                capture_output=True,
                timeout=5
            )
            time.sleep(1)
            
            # Start new port-forward for this namespace (in background)
            # Note: This runs on server via SSH
            subprocess.Popen([
                'ssh', 'gl3',
                f'kubectl port-forward svc/gw-nginx 9090:80 -n {namespace}'
            ])
            
            # Wait for port-forward to establish
            time.sleep(3)
            output.console_log("  ✓ Gateway port-forward started for this namespace")
            
        except Exception as e:
            output.console_log(f"  ⚠ Error starting gateway port-forward: {e}")
            output.console_log("  Continuing anyway - ensure port-forward is running manually")
            output.console_log(f"  Manual command: ssh gl3 'kubectl port-forward svc/gw-nginx 9090:80 -n {namespace}'")
        
        # 8. Get gateway URL and verify accessibility
        # NOTE: Gateway is accessible on HOST at http://localhost:9090 via SSH tunnel
        # The gateway service name is 'gw-nginx' in the namespace on SERVER
        # Prerequisites:
        #   - Server: kubectl port-forward must be running (just started above)
        #   - Host: SSH tunnel must be running (tunnels-local.sh - started once per experiment)
        output.console_log("  Verifying gateway accessibility...")
        try:
            import requests
            # This accesses http://localhost:9090 on HOST, which tunnels to SERVER
            response = requests.get(f"{self.GATEWAY_URL}{self.GATEWAY_TEST_ENDPOINT}", timeout=10)
            if response.status_code == 200:
                output.console_log("  ✓ Gateway accessible via SSH tunnel")
            else:
                output.console_log(f"  ⚠ Gateway returned status {response.status_code}")
        except Exception as e:
            output.console_log(f"  ⚠ Could not verify gateway: {e}")
            output.console_log("  Continuing anyway - ensure SSH tunnel is running")
            output.console_log("  Host: ./scripts/tunnels-local.sh (should be running from experiment setup)")
    
    # Store namespace for cleanup later
    context.run_dir.mkdir(parents=True, exist_ok=True)
    with open(context.run_dir / "namespace.txt", "w") as f:
        f.write(namespace)
```

## 5. Prometheus Query Functions

**Location**: Add to `RunnerConfig` class

**Note**: Prometheus queries run on **HOST MACHINE** but access Prometheus on **SERVER**:
- Prometheus URL: `http://localhost:30000` (accessible via SSH tunnel from host)
- Server must have: kubectl port-forward running (combined-tunnels-server.sh)
- Host must have: SSH tunnel running (tunnels-local.sh)

```python
# Prometheus configuration
PROMETHEUS_URL = "http://localhost:30000"  # Via SSH tunnel

def query_prometheus(self, query: str, timeout: int = 30) -> Optional[Dict]:
    """Query Prometheus API.
    
    NOTE: This runs on HOST and accesses Prometheus on SERVER via SSH tunnel.
    Prerequisites:
      - Server: kubectl port-forward svc/prometheus-nodeport 30000:9090 -n monitoring
      - Host: ssh -L 30000:localhost:30000 gl3
    
    Args:
        query: PromQL query string
        timeout: Request timeout in seconds
    
    Returns:
        Parsed JSON response or None on error
    """
    try:
        import requests
        
        # Prometheus URL on HOST (tunnels to SERVER)
        url = f"{self.PROMETHEUS_URL}/api/v1/query"
        params = {'query': query}
        
        response = requests.get(url, params=params, timeout=timeout)
        response.raise_for_status()
        
        data = response.json()
        if data['status'] == 'success':
            return data['data']
        else:
            output.console_log(f"  ⚠ Prometheus query failed: {data.get('error', 'Unknown error')}")
            return None
            
    except requests.exceptions.RequestException as e:
        output.console_log(f"  ⚠ Prometheus query error: {e}")
        output.console_log("  Ensure SSH tunnel is running: ./scripts/tunnels-local.sh")
        return None
    except Exception as e:
        output.console_log(f"  ⚠ Unexpected error querying Prometheus: {e}")
        return None

def get_cpu_usage(self, namespace: str) -> Optional[float]:
    """Get average CPU usage for all pods in namespace.
    
    Args:
        namespace: Kubernetes namespace
    
    Returns:
        Average CPU usage (0.0-1.0) or None on error
    """
    # Query CPU usage rate over 5 minutes
    query = f'rate(container_cpu_usage_seconds_total{{namespace="{namespace}"}}[5m])'
    
    data = self.query_prometheus(query)
    if not data or 'result' not in data:
        return None
    
    # Calculate average across all pods
    values = []
    for result in data['result']:
        if 'value' in result and len(result['value']) > 1:
            try:
                values.append(float(result['value'][1]))
            except (ValueError, IndexError):
                continue
    
    if not values:
        return None
    
    avg_cpu = sum(values) / len(values)
    return avg_cpu

def get_memory_usage(self, namespace: str) -> Optional[float]:
    """Get average memory usage for all pods in namespace (in bytes).
    
    Args:
        namespace: Kubernetes namespace
    
    Returns:
        Average memory usage in bytes or None on error
    """
    # Query memory working set
    query = f'container_memory_working_set_bytes{{namespace="{namespace}"}}'
    
    data = self.query_prometheus(query)
    if not data or 'result' not in data:
        return None
    
    # Calculate average across all pods
    values = []
    for result in data['result']:
        if 'value' in result and len(result['value']) > 1:
            try:
                values.append(float(result['value'][1]))
            except (ValueError, IndexError):
                continue
    
    if not values:
        return None
    
    avg_memory = sum(values) / len(values)
    return avg_memory
```

## 6. Update `stop_measurement` Hook

**Location**: Update `stop_measurement` method in `RunnerConfig.py`

```python
def stop_measurement(self, context: RunnerContext) -> None:
    """Perform any activity here required for stopping measurements."""
    
    output.console_log("Stopping measurement phase...")
    
    # Record end timestamp
    with open(context.run_dir / "measurement_end.txt", "w") as f:
        f.write(str(time.time()))
    
    # Query Prometheus metrics
    namespace_file = context.run_dir / "namespace.txt"
    if namespace_file.exists():
        with open(namespace_file, 'r') as f:
            namespace = f.read().strip()
        
        output.console_log(f"  Querying Prometheus metrics for namespace '{namespace}'...")
        
        # Query CPU usage
        cpu_usage = self.get_cpu_usage(namespace)
        if cpu_usage is not None:
            output.console_log(f"  CPU usage: {cpu_usage:.4f}")
            with open(context.run_dir / "prometheus_cpu.txt", "w") as f:
                f.write(str(cpu_usage))
        else:
            output.console_log("  ⚠ Could not query CPU usage")
        
        # Query memory usage
        memory_usage = self.get_memory_usage(namespace)
        if memory_usage is not None:
            output.console_log(f"  Memory usage: {memory_usage / (1024**2):.2f} MB")
            with open(context.run_dir / "prometheus_memory.txt", "w") as f:
                f.write(str(memory_usage))
        else:
            output.console_log("  ⚠ Could not query memory usage")
    else:
        output.console_log("  ⚠ Namespace file not found - skipping Prometheus queries")
```

## 7. Update `populate_run_data` Hook

**Location**: Update `populate_run_data` method in `RunnerConfig.py`

```python
def populate_run_data(self, context: RunnerContext) -> Optional[Dict[str, Any]]:
    """Parse and process any measurement data here.
    Returns a dictionary with keys `self.run_table_model.data_columns` and their values populated"""
    
    output.console_log("Parsing measurement data...")
    
    locust_output_dir = context.run_dir / "locust"
    results = {}
    
    # Parse Locust CSV results
    locust_stats_file = locust_output_dir / "results_stats.csv"
    if locust_stats_file.exists():
        try:
            with open(locust_stats_file, 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    if row.get('Name') == 'Aggregated':
                        results['throughput_rps'] = float(row.get('Requests/s', 0))
                        results['avg_latency_ms'] = float(row.get('Average Response Time', 0))
                        results['p95_latency_ms'] = float(row.get('95%', 0))
                        
                        total_requests = int(row.get('Request Count', 0))
                        failures = int(row.get('Failure Count', 0))
                        results['request_count'] = total_requests
                        results['failure_rate'] = failures / total_requests if total_requests > 0 else 0.0
                        
                        output.console_log(f"  Locust metrics: {results['throughput_rps']:.2f} RPS, {results['avg_latency_ms']:.2f}ms avg latency")
        except Exception as e:
            output.console_log(f"  ⚠ Error parsing Locust CSV: {e}")
            results['throughput_rps'] = 0.0
            results['avg_latency_ms'] = 0.0
            results['p95_latency_ms'] = 0.0
            results['failure_rate'] = 0.0
            results['request_count'] = 0
    else:
        output.console_log("  ⚠ Locust stats file not found")
        results['throughput_rps'] = 0.0
        results['avg_latency_ms'] = 0.0
        results['p95_latency_ms'] = 0.0
        results['failure_rate'] = 0.0
        results['request_count'] = 0
    
    # Parse Prometheus metrics
    cpu_file = context.run_dir / "prometheus_cpu.txt"
    memory_file = context.run_dir / "prometheus_memory.txt"
    
    if cpu_file.exists():
        try:
            with open(cpu_file, 'r') as f:
                results['cpu_usage_avg'] = float(f.read().strip())
                output.console_log(f"  CPU usage: {results['cpu_usage_avg']:.4f}")
        except Exception as e:
            output.console_log(f"  ⚠ Error reading CPU metrics: {e}")
            results['cpu_usage_avg'] = 0.0
    else:
        results['cpu_usage_avg'] = 0.0
    
    if memory_file.exists():
        try:
            with open(memory_file, 'r') as f:
                # Memory is in bytes, convert to MB for readability (optional)
                results['memory_usage_avg'] = float(f.read().strip())
                output.console_log(f"  Memory usage: {results['memory_usage_avg'] / (1024**2):.2f} MB")
        except Exception as e:
            output.console_log(f"  ⚠ Error reading memory metrics: {e}")
            results['memory_usage_avg'] = 0.0
    else:
        results['memory_usage_avg'] = 0.0
    
    return results
```

## 8. Update `stop_run` Hook

**Location**: Update `stop_run` method in `RunnerConfig.py`

```python
def stop_run(self, context: RunnerContext) -> None:
    """Perform any activity here required for stopping the run.
    Activities after stopping the run should also be performed here."""
    
    topology = context.execute_run['topology']
    size = context.execute_run['system_size']
    replicate = context.run_nr
    
    output.console_log(f"Stopping run: topology={topology}, size={size}, replicate={replicate}")
    
    # Optional: Clean up namespace (set to False to keep for debugging)
    CLEANUP_NAMESPACE = False  # Set to True to delete namespace after each run
    
    if CLEANUP_NAMESPACE:
        namespace_file = context.run_dir / "namespace.txt"
        if namespace_file.exists():
            with open(namespace_file, 'r') as f:
                namespace = f.read().strip()
            self.delete_namespace(namespace)
    else:
        output.console_log("  (Keeping namespace for debugging - set CLEANUP_NAMESPACE=True to delete)")
```

## 9. Add Required Imports

**Location**: Top of `RunnerConfig.py` (if not already present)

```python
import requests  # Add this if not already imported
```

## Testing Checklist

### Prerequisites Setup

**On Server (gl3)**:
1. ✅ minikube running: `kubectl get nodes`
2. ✅ Prometheus deployed: `kubectl get svc -n monitoring prometheus-nodeport`
3. ✅ Start port-forwards: `./scripts/combined-tunnels-server.sh <namespace>`

**On Host Machine**:
1. ✅ SSH access to gl3: `ssh gl3` should work
2. ✅ Start SSH tunnels: `./scripts/tunnels-local.sh`
3. ✅ Verify connectivity:
   - `curl http://localhost:9090/s0` (gateway)
   - `curl http://localhost:30000/api/v1/status/config` (Prometheus)

### Implementation Testing

1. **Test workmodel mapping**: Verify all 18 combinations map correctly (on HOST)
2. **Test namespace creation**: Create and verify namespace (kubectl on HOST or via SSH to SERVER)
3. **Test K8sParameters generation**: Generate config and verify paths (on HOST)
4. **Test manual deployment**: Run K8sDeployer manually on SERVER with generated config
5. **Test Prometheus queries**: Query Prometheus API from HOST (via SSH tunnel)
6. **Test single run**: Execute one complete run end-to-end (Experiment Runner on HOST)
7. **Test multiple runs**: Execute 2-3 runs to verify namespace isolation
8. **Test cleanup**: Verify namespace deletion works (if enabled)

## Notes

### Host vs Server Operations

**HOST MACHINE** (where Experiment Runner runs):
- Experiment Runner execution
- SSH tunnels to server (`tunnels-local.sh`)
- Accessing services via `localhost` (tunnels to server)
- kubectl commands (if context points to server cluster)

**SERVER (gl3)** (where minikube runs):
- minikube cluster
- muBench deployments (K8sDeployer execution)
- Prometheus
- kubectl port-forwards (`combined-tunnels-server.sh`)

### SSH Tunnel Setup

**Server-side** (run first):
```bash
# On server (gl3)
cd /root/muBench
./scripts/combined-tunnels-server.sh <gateway-namespace>
# Sets up:
# - kubectl port-forward svc/gw-nginx 9090:80 -n <namespace>
# - kubectl port-forward svc/prometheus-nodeport 30000:9090 -n monitoring
```

**Host-side** (run after server port-forwards):
```bash
# On host machine
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh
# Sets up:
# - ssh -L 9090:localhost:9090 gl3
# - ssh -L 30000:localhost:30000 gl3
```

### Other Notes

- **Namespace Naming**: Format is `mubench-{topology}-{size}-{replicate}` (e.g., `mubench-sequential_fanout-5-0`)
- **Workmodel Paths**: All paths are relative to muBench root directory
- **Error Handling**: All functions include error handling and logging
- **Timeouts**: Adjust timeouts based on deployment speed and system performance
- **K8sDeployer Execution**: May need to run via SSH to server or ensure kubectl context is set correctly

