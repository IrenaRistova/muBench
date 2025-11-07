# Research: SSH Tunnel Testing Without Minikube

## Research Topic
How to SSH from host machine to muBench application and run `RunnerParameters-external.json` without requiring minikube, using SSH tunnels to access the nginx gateway.

## Executive Summary

The current muBench setup requires:
1. **Kubernetes cluster** (minikube) running on the server
2. **kubectl port-forward** to expose the nginx gateway service on port 9090
3. **SSH tunnel** from host machine to server to access the forwarded port

The user wants to test SSH tunneling functionality without minikube installed. This research explores:
- Current SSH tunnel architecture and scripts
- How the Runner uses the nginx gateway
- Alternatives to minikube for testing SSH tunnels
- Standalone nginx setup options

## Research Findings

### 1. Current SSH Tunnel Architecture

#### Connection Path
```
Host Machine → glgate (145.108.225.3:42224) → gl3 (Remote Server)
```

#### Existing Scripts

**Server-side (gl3):**
- `scripts/gateway-tunnel.sh` - Sets up `kubectl port-forward svc/gw-nginx 9090:80`
- `scripts/monitoring-tunnel.sh` - Sets up port forwarding for monitoring tools

**Host-side:**
- `scripts/gateway-tunnel-local.sh` - Creates SSH tunnel: `ssh -J glgate@145.108.225.3:42224 -N -L 9090:localhost:9090 ira340@gl3`
- `scripts/monitoring-tunnel-local.sh` - Creates SSH tunnels for monitoring tools

#### Key Components

1. **Nginx Gateway Service** (`gw-nginx`)
   - Kubernetes Service type: `LoadBalancer` (but uses port-forward on minikube)
   - Listens on port 80 inside the cluster
   - Exposed via `kubectl port-forward` on port 9090
   - Configuration: `Deployers/K8sDeployer/Templates/ConfigMapNginxGwTemplate.yaml`

2. **SSH Tunnel Command**
   ```bash
   ssh -J glgate@145.108.225.3:42224 \
       -N \
       -L 9090:localhost:9090 \
       ira340@gl3
   ```
   - Uses ProxyJump (`-J`) to go through jump host `glgate`
   - Forwards local port 9090 to remote localhost:9090
   - `-N` flag prevents command execution (tunnel only)

### 2. Runner.py Gateway Usage

**Location:** `Benchmarks/Runner/Runner.py`

**Key Code:**
```python
ms_access_gateway = runner_parameters["ms_access_gateway"]  # e.g., "http://localhost:9090"
r = requests.get(f"{ms_access_gateway}/{event['service']}")  # e.g., "http://localhost:9090/s0"
```

**RunnerParameters-external.json:**
```json
{
    "RunnerParameters": {
        "ms_access_gateway": "http://localhost:9090",
        "workload_files_path_list": ["SimulationWorkspace/workload.json"],
        "workload_type": "greedy",
        "workload_events": 5000,
        "thread_pool_size": 10
    }
}
```

**How it works:**
- Runner sends HTTP GET requests to `http://localhost:9090/{service_name}`
- Example: `http://localhost:9090/s0` to access service `s0`
- The nginx gateway proxies these requests to the actual microservices in the cluster

### 3. Nginx Gateway Configuration

**Template:** `Deployers/K8sDeployer/Templates/ConfigMapNginxGwTemplate.yaml`

**Key Configuration:**
```nginx
server {
    listen 80;
    location / {
        resolver {{RESOLVER}};
        proxy_pass http:/$request_uri.{{NAMESPACE}}.svc.cluster.local{{PATH}};
        proxy_http_version 1.1;
    }
}
```

**How it works:**
- Receives requests like `/s0`
- Resolves to `http://s0.default.svc.cluster.local/api/v1`
- Proxies to the Kubernetes service

### 4. Alternatives to Minikube for Testing

#### Option A: Standalone Nginx Container (Recommended)

**Approach:** Run nginx in a Docker container directly, bypassing Kubernetes entirely.

**Advantages:**
- No minikube/kubectl required
- Simple setup
- Can test SSH tunnel functionality
- Can use same nginx configuration

**Limitations:**
- Won't proxy to actual microservices (they need Kubernetes)
- Can only test tunnel connectivity, not full application flow
- Need to modify nginx config for standalone use

**Implementation:**
```bash
# On server (gl3)
docker run -d --name nginx-gateway \
    -p 9090:80 \
    -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
    nginx
```

#### Option B: Simple HTTP Server (Mock Gateway)

**Approach:** Use Python's `http.server` or a simple HTTP server to mock the gateway.

**Advantages:**
- No Docker required
- Very simple setup
- Good for testing SSH tunnel connectivity

**Limitations:**
- Doesn't match nginx behavior
- Can't test actual gateway functionality
- Only useful for tunnel testing

**Implementation:**
```bash
# On server (gl3)
python3 -m http.server 9090
```

#### Option C: Docker Compose with Nginx

**Approach:** Use docker-compose to run nginx without Kubernetes.

**Advantages:**
- More realistic setup
- Can include other services if needed
- Easy to manage

**Limitations:**
- Still requires Docker
- Won't have Kubernetes service discovery

### 5. Testing Strategy Without Minikube

#### Minimal Test Setup

1. **On Server (gl3):**
   ```bash
   # Option 1: Simple nginx container
   docker run -d --name test-nginx -p 9090:80 nginx
   
   # Option 2: Python HTTP server
   python3 -m http.server 9090
   ```

2. **On Host Machine:**
   ```bash
   # Use existing gateway-tunnel-local.sh script
   ./scripts/gateway-tunnel-local.sh
   
   # Or manually:
   ssh -J glgate@145.108.225.3:42224 -N -L 9090:localhost:9090 ira340@gl3
   ```

3. **Test Connection:**
   ```bash
   curl -v http://localhost:9090
   ```

4. **Run Runner (if nginx is configured):**
   ```bash
   python3 Benchmarks/Runner/Runner.py -c Configs/RunnerParameters-external.json
   ```

#### What Can Be Tested

✅ **Can Test:**
- SSH tunnel connectivity
- Port forwarding functionality
- Network routing through jump host
- Basic HTTP connectivity

❌ **Cannot Test (without Kubernetes):**
- Actual microservice routing
- Service discovery
- Full application behavior
- Kubernetes-specific features

### 6. Current Script Analysis

#### `scripts/gateway-tunnel.sh` (Server-side)

**Current behavior:**
- Uses `kubectl port-forward svc/gw-nginx 9090:80`
- Requires Kubernetes cluster running
- Requires `gw-nginx` service to exist

**For testing without minikube:**
- Script needs modification or alternative
- Could check if kubectl is available
- Could fall back to direct nginx container

#### `scripts/gateway-tunnel-local.sh` (Host-side)

**Current behavior:**
- Creates SSH tunnel to `localhost:9090` on server
- Works independently of how port 9090 is exposed on server
- **This script will work as-is** for testing!

**Key insight:** The host-side script doesn't care how port 9090 is exposed on the server. It just tunnels to whatever is listening on that port.

### 7. Recommended Approach

#### For Testing SSH Tunnel Only

1. **On Server (gl3):**
   ```bash
   # Start simple nginx container
   docker run -d --name test-nginx -p 9090:80 nginx
   ```

2. **On Host Machine:**
   ```bash
   # Use existing script
   ./scripts/gateway-tunnel-local.sh
   
   # Or run manually in background
   ssh -J glgate@145.108.225.3:42224 -N -L 9090:localhost:9090 ira340@gl3 &
   ```

3. **Test:**
   ```bash
   curl http://localhost:9090
   # Should return nginx default page
   ```

#### For Testing Runner with Mock Gateway

1. **Create mock nginx config** that responds to `/s0` requests
2. **Run nginx container** with mock config
3. **Set up SSH tunnel** using existing script
4. **Run Runner** - it will send requests to `http://localhost:9090/s0`

## Key Insights

1. **Host-side SSH tunnel script works independently** - It doesn't require minikube, only needs something listening on port 9090 on the server.

2. **Server-side port-forward script requires Kubernetes** - The `gateway-tunnel.sh` script uses `kubectl port-forward`, which requires a running cluster.

3. **Alternative server-side setup needed** - For testing without minikube, need to run nginx (or another service) directly on port 9090.

4. **Runner expects HTTP responses** - The Runner will work with any HTTP server on port 9090, but won't get actual microservice responses without Kubernetes.

5. **SSH tunnel architecture is sound** - The tunnel setup through the jump host works regardless of what's on the server side.

## Open Questions

1. **What level of testing is needed?**
   - Just SSH tunnel connectivity?
   - Mock gateway responses?
   - Full application behavior?

2. **Should we create a modified `gateway-tunnel.sh` script** that can work without Kubernetes?

3. **What nginx configuration should be used** for standalone testing?

4. **Should we create a docker-compose setup** for testing without minikube?

## Next Steps

1. **Create standalone nginx setup script** for testing without minikube
2. **Document testing procedure** for SSH tunnels without Kubernetes
3. **Create mock nginx configuration** if Runner testing is needed
4. **Update SSH_TUNNEL_GUIDE.md** with non-minikube testing options

## References

- `scripts/SSH_TUNNEL_GUIDE.md` - Current tunnel setup guide
- `scripts/gateway-tunnel.sh` - Server-side port forwarding
- `scripts/gateway-tunnel-local.sh` - Host-side SSH tunnel
- `Benchmarks/Runner/Runner.py` - How Runner uses gateway
- `Configs/RunnerParameters-external.json` - Runner configuration
- `Deployers/K8sDeployer/Templates/ConfigMapNginxGwTemplate.yaml` - Nginx gateway config

