# Handoff Prompt for Host Machine (Experiment Runner Integration)

## Context for New Cursor Session

I'm continuing work on the **experiment-runner-locust-integration** feature. The POC (Proof of Concept) is complete and tested. Now I need to implement **full deployment integration** with actual muBench applications deployed to minikube on the server.

## Current Status

### ✅ Completed (POC Phase)
- Experiment Runner config created: `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
- Locust integration working (headless execution, CSV parsing)
- SSH tunnel integration working
- Metric parsing working (Locust metrics: throughput, latency, failure rate)
- **18 test runs completed** with standalone mock gateway
- All 18 workmodel files generated and tested on server

### 🔄 Next Phase: Full Deployment Integration
- Integrate muBench deployment in `start_run` hook
- Integrate Prometheus metric collection in `stop_measurement` hook
- Scale to 540 runs (6 topologies × 3 sizes × 30 repetitions)
- Duration: 10 minutes per run (2 min warm-up + 8 min measurement)

## Server Setup (Already Complete)

**On gl3 server:**
- ✅ minikube running
- ✅ mubench container running
- ✅ Prometheus installed (Prometheus-only, no Grafana/Jaeger/Kiali)
- ✅ All 18 workmodel files generated and tested
- ✅ Combined port-forward script: `scripts/combined-tunnels-server.sh`

**Server scripts available:**
- `scripts/deploy-workmodel.sh` - Deploy workmodel to namespace
- `scripts/verify-deployment.sh` - Verify pods are running
- `scripts/cleanup-namespace.sh` - Delete namespace after run
- `scripts/get-gateway-url.sh` - Get gateway URL for namespace
- `scripts/combined-tunnels-server.sh` - Start gateway + Prometheus port-forwards

## Key Files to Review

### Experiment Runner Config (Main File to Modify)
**Location:** `~/Documents/Research Project/experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`

**Current state:**
- Has placeholder TODOs in `start_run`, `stop_measurement`, `populate_run_data` hooks
- Locust integration complete
- SSH tunnel integration complete
- Metric parsing for Locust complete
- CPU/memory metrics are placeholders (0.0)

### Implementation Guide
**Location:** `~/Documents/Research Project/muBench/specs/active/experiment-runner-locust-integration/DEPLOYMENT_IMPLEMENTATION.md`

**Contains:**
- Complete code snippets for all hooks
- Workmodel mapping function
- Namespace management functions
- K8sParameters generation
- Prometheus query functions
- Example PromQL queries

### Feature Brief
**Location:** `~/Documents/Research Project/muBench/specs/active/experiment-runner-locust-integration/feature-brief.md`

**Contains:**
- Complete project context
- Workmodel status (all 18 files exist)
- Integration workflow
- Testing strategy

## What Needs to Be Implemented

### 1. Workmodel Mapping Function
**Location:** Add to `RunnerConfig.py`

**Purpose:** Map topology + size → workmodel file path

**Mapping:**
- `sequential_fanout` + `5` → `Examples/workmodel-serial-5services.json`
- `parallel_fanout` + `20` → `Examples/workmodel-parallel-20services.json`
- `centralized_star` + `20` → `Examples/workmodelA.json`
- `centralized_star` + `5` → `Examples/workmodelA-5services.json`
- `hierarchical_tree` + `20` → `Examples/workmodelC.json`
- `hierarchical_tree` + `5` → `Examples/workmodelC-5services.json`
- `probabilistic_tree` + `20` → `Examples/workmodelC-multi.json`
- `probabilistic_tree` + `5` → `Examples/workmodelC-multi-5services.json`
- `complex_mesh` + `20` → `Examples/workmodelD.json`
- `complex_mesh` + `5` → `Examples/workmodelD-5services.json`

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 3

### 2. Namespace Management
**Location:** Add to `RunnerConfig.py`

**Purpose:** Create unique namespace per run: `mubench-{topology}-{size}-{replicate}`

**Functions needed:**
- Create namespace
- Check if namespace exists
- Delete namespace (optional cleanup)

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 4

### 3. K8sParameters.json Generation
**Location:** Add to `RunnerConfig.py`

**Purpose:** Generate per-run config file with correct workmodel path and namespace

**Template:** `muBench/Configs/K8sParameters.json`

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 5

### 4. Deployment in `start_run` Hook
**Location:** `RunnerConfig.py` → `start_run()` method

**Steps:**
1. Get topology and size from `context.execute_run`
2. Map to workmodel file path
3. Create namespace: `mubench-{topology}-{size}-{replicate}`
4. Generate K8sParameters.json for this run
5. Execute: `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c <config>`
6. Wait for pods ready: `kubectl wait --for=condition=ready pod --all -n <namespace> --timeout=300s`
7. Verify gateway accessible

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 6

### 5. Prometheus Integration in `stop_measurement` Hook
**Location:** `RunnerConfig.py` → `stop_measurement()` method

**Purpose:** Query Prometheus for CPU and memory metrics

**Prometheus URL:** `http://localhost:30000` (via SSH tunnel)

**Queries needed:**
- CPU: `rate(container_cpu_usage_seconds_total{namespace="<ns>"}[5m])`
- Memory: `container_memory_working_set_bytes{namespace="<ns>"}`

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 7

### 6. Prometheus Parsing in `populate_run_data` Hook
**Location:** `RunnerConfig.py` → `populate_run_data()` method

**Purpose:** Parse Prometheus query results and populate `cpu_usage_avg` and `memory_usage_avg`

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 8

### 7. Cleanup in `stop_run` Hook
**Location:** `RunnerConfig.py` → `stop_run()` method

**Purpose:** Optionally delete namespace after run

**See:** `DEPLOYMENT_IMPLEMENTATION.md` section 9

## Paths and Configuration

### Directory Structure
```
~/Documents/Research Project/
├── experiment-runner/
│   └── examples/
│       └── mubench-benchmarking/
│           └── RunnerConfig.py  ← MAIN FILE TO MODIFY
└── muBench/  ← Sibling directory
    ├── Deployers/K8sDeployer/RunK8sDeployer.py
    ├── Configs/K8sParameters.json
    ├── Examples/workmodel-*.json (18 files)
    └── scripts/ (helper scripts on server)
```

### Path Resolution in RunnerConfig.py
```python
ROOT_DIR = Path(dirname(realpath(__file__)))
MUBENCH_DIR = ROOT_DIR.parent.parent.parent / 'muBench'
```

### Key Paths
- Locust file: `MUBENCH_DIR / 'Benchmarks' / 'Locust' / 'locustfile.py'`
- K8sDeployer: `MUBENCH_DIR / 'Deployers' / 'K8sDeployer' / 'RunK8sDeployer.py'`
- K8sParameters template: `MUBENCH_DIR / 'Configs' / 'K8sParameters.json'`
- Examples directory: `MUBENCH_DIR / 'Examples'`

## Server Access

**SSH to server:** `ssh gl3`

**Server scripts location:** `/home/ira340/muBench/scripts/`

**To deploy manually (for testing):**
```bash
# On server
./scripts/deploy-workmodel.sh <namespace> <workmodel-path>
./scripts/verify-deployment.sh <namespace> <gateway-url>
./scripts/combined-tunnels-server.sh  # Start port-forwards
```

## Testing Strategy

### Phase 1: Single Run Test
1. Test deployment with one topology+size combination
2. Verify namespace creation
3. Verify pods deploy correctly
4. Test Locust execution
5. Test Prometheus queries
6. Verify metric parsing

### Phase 2: Multiple Runs
1. Test with 2-3 runs
2. Verify namespace management (create/delete)
3. Test error handling
4. Verify metrics collection

### Phase 3: Scale Up
1. Run subset (e.g., 1 topology × 1 size × 5 repetitions)
2. Monitor resource usage
3. Test restart capability

## Prometheus Setup

**Status:** ✅ Already installed on server (Prometheus-only)

**Access:**
- Server: `http://localhost:30000` (after port-forward)
- Host: `http://localhost:30000` (after SSH tunnel)

**Port-forward:** Run `./scripts/combined-tunnels-server.sh` on server

**SSH tunnel:** Use your combined SSH tunnel script on host

## Key Differences from POC

| Aspect | POC | Full Experiment |
|--------|-----|-----------------|
| Runs | 18 | 540 |
| Duration/run | 10s | 10m (2m warm-up + 8m measurement) |
| Deployment | None | Per run (different topology+size) |
| Gateway | Mock (same) | Real (per deployment) |
| Prometheus | Not used | Required (CPU/memory metrics) |
| CPU/Memory | 0.0 (placeholders) | Real values from Prometheus |
| Namespace | None | Unique per run |

## Implementation Order

1. **Add workmodel mapping function** (section 3 of DEPLOYMENT_IMPLEMENTATION.md)
2. **Add namespace management functions** (section 4)
3. **Add K8sParameters generation** (section 5)
4. **Update `start_run` hook** (section 6)
5. **Add Prometheus query functions** (section 7)
6. **Update `stop_measurement` hook** (section 7)
7. **Update `populate_run_data` hook** (section 8)
8. **Update `stop_run` hook** (section 9)
9. **Test single run end-to-end**
10. **Test multiple runs**

## Questions to Answer

1. How to execute K8sDeployer from host? (SSH command or direct kubectl?)
2. How to wait for pods ready from host? (SSH + kubectl wait)
3. How to query Prometheus from host? (HTTP requests to localhost:30000)
4. Should namespaces be deleted after each run? (configurable option)

## Next Steps

1. Read `DEPLOYMENT_IMPLEMENTATION.md` for complete code snippets
2. Review current `RunnerConfig.py` to understand structure
3. Implement functions one by one
4. Test each function individually
5. Integrate into hooks
6. Test end-to-end with single run
7. Scale to multiple runs

## Important Notes

- **All 18 workmodel files exist** and have been tested on server
- **Prometheus is installed** and accessible on port 30000
- **Server scripts are ready** for deployment and verification
- **SSH tunnel setup** is the same as POC (just need to ensure port-forwards are running on server)
- **Path resolution** uses relative paths from Experiment Runner to muBench (sibling directories)

## Files to Read First

1. `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py` - Current implementation
2. `muBench/specs/active/experiment-runner-locust-integration/DEPLOYMENT_IMPLEMENTATION.md` - Implementation guide
3. `muBench/specs/active/experiment-runner-locust-integration/feature-brief.md` - Full context
4. `muBench/Configs/K8sParameters.json` - Config template

---

**Ready to implement!** Start with the workmodel mapping function and work through the implementation guide systematically.

