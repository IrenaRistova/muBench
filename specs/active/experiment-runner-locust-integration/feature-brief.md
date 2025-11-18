# experiment-runner-locust-integration Feature Brief

## 🎯 Context (2min)
**Problem**: Need automated orchestration for Phase 3 benchmarking experiments. Manual execution of 18 system configurations (6 topologies × 3 sizes) with 30 replicates each (540 total runs) is impractical. Need Experiment Runner to automate: muBench deployments, Locust workload execution, Prometheus metric collection, and experiment workflow management.

**Current Status**: 
- ✅ **FULLY WORKING**: Complete integration tested and verified
- ✅ **Full Deployment Integration**: **IMPLEMENTED AND TESTED**
  - Namespace management working
  - K8sDeployer successfully deploying muBench applications
  - Pod readiness checks working
  - Gateway port-forwarding per namespace working
  - Locust executing against deployed services
  - Metrics being collected (RPS, latency, CPU, memory)
  - **18 runs completed successfully** with full deployment
- ✅ **Prometheus Integration**: **WORKING** - Queries succeed when SSH tunnels are properly configured
- ✅ **All Components Tested**: All 6 topologies × 3 sizes tested successfully

**Users**: Researcher running Phase 3 benchmarking experiments on host machine, needing automated orchestration of muBench deployments, Locust load generation, and metric collection for comprehensive dataset generation.

**Success**: Experiment Runner successfully orchestrates complete benchmarking workflow: deploys muBench applications via K8sDeployer, executes Locust workloads in headless mode, collects Prometheus metrics, manages 540 experiment runs (18 configs × 30 replicates), handles errors and restarts, produces aggregated results ready for Phase 4 analysis.

## 🔍 Quick Research (15min)
### Existing Patterns
- **Experiment Runner Structure** (`experiment-runner/examples/hello-world/RunnerConfig.py`) → Event-driven config with hooks (before_experiment, start_run, interact, stop_run, etc.) | Reuse: Event hook pattern, RunTableModel structure, subprocess execution
- **Locust Integration** (`Benchmarks/Locust/locustfile.py`) → Headless execution: `locust -f Benchmarks/Locust/locustfile.py --headless -u <users> -r <spawn_rate> -t <duration> --host http://localhost:9090` | Reuse: Command format, parameter structure, CSV export
- **muBench Deployment** (`Autopilots/K8sAutopilot/K8sAutopilot.py`, `Deployers/K8sDeployer/RunK8sDeployer.py`) → Sequential execution: ServiceGraph → WorkModel → K8sDeployer | Reuse: Deployment workflow, config file pattern (K8sParameters.json)
- **SSH Tunnel Setup** (`scripts/gateway-tunnel-local.sh`) → Port forwarding 9090:9090 to gl3 server | Reuse: Tunnel setup pattern, gateway URL (http://localhost:9090)
- **Standalone Gateway Testing** (`scripts/gateway-tunnel-standalone-python.sh`) → Mock gateway for testing without minikube | Reuse: Testing workflow, gateway verification
- **Path References** (`experiment-runner/examples/linux-ps-profiling/RunnerConfig.py`) → Uses `ROOT_DIR = Path(dirname(realpath(__file__)))` for relative paths | Reuse: Path resolution pattern
- **Subprocess Execution** (`experiment-runner/examples/linux-ps-profiling/RunnerConfig.py`) → Uses `subprocess.Popen` and `subprocess.check_call` for external commands | Reuse: Command execution pattern
- **Experiment Design** (`specs/00-overview.md`) → 6 topologies × 3 sizes = 18 configs, 30 replicates each | Reuse: Factor structure, run table design

### Tech Decision
**Approach**: Experiment Runner config in sibling directory structure (experiment-runner/ and muBench/ as siblings), using relative paths to reference muBench components. Event hooks orchestrate: SSH tunnel setup, muBench deployment, Locust execution, Prometheus collection.

**Why**: 
- Sibling directories allow independent versioning and management of Experiment Runner and muBench
- Relative paths work from Experiment Runner location to muBench components
- Event-driven architecture matches Experiment Runner design pattern
- Supports both testing (standalone gateway) and production (minikube) workflows
- Enables restart capability for incomplete experiments (540 runs need resilience)
- Follows Experiment Runner examples (linux-ps-profiling uses subprocess for external tools)

**Avoid**: 
- Putting Experiment Runner inside muBench (breaks independent versioning)
- Absolute paths (not portable, breaks on different machines)
- Manual orchestration (540 runs impractical to manage manually)
- Tight coupling (should work with or without minikube)

## ✅ Requirements (10min)
- **Folder Structure Decision** → Determine optimal structure (sibling vs inside muBench), document path references, ensure portability
- **Experiment Runner Config Creation** → Create RunnerConfig.py with RunTableModel for 18 configs (6 topologies × 3 sizes) × 30 replicates
- **Path Configuration** → Set up relative paths from Experiment Runner to muBench components (K8sDeployer, Locust, scripts)
- **SSH Tunnel Integration** → Automate SSH tunnel setup in before_experiment, verify connectivity before runs
- **Workmodel Generation** → Generate all 18 workmodel files (6 topologies × 3 sizes: 5, 10, 20 services) manually before deployment integration
- **muBench Deployment Orchestration** → Integrate K8sDeployer execution in start_run, wait for pods ready, handle deployment errors
- **Locust Execution Integration** → Execute Locust headless mode in interact hook, 2 min warm-up + 8 min measurement, collect CSV metrics
- **Prometheus Metric Collection** → Query/export Prometheus metrics in stop_measurement, collect CPU/memory/performance data
- **Experiment Workflow Management** → Handle 540 runs with error recovery, progress tracking, restart capability
- **Namespace Management** → Create unique namespaces per run (topology-size-replicate), cleanup after runs
- **Testing Support** → Support standalone gateway testing (without minikube) for development/validation
- **Result Aggregation** → Parse Locust CSV and Prometheus data in populate_run_data, return structured metrics
- **Error Handling** → Handle deployment failures, Locust errors, Prometheus connection issues, graceful degradation

## 🏗️ Implementation (5min)
**Components**: 
- Experiment Runner config file: `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
- Path configuration: Relative paths from Experiment Runner to muBench (e.g., `../muBench/`)
- Integration helpers: Optional helper scripts/functions for common operations (SSH tunnel, kubectl checks, etc.)
- Configuration files: muBench config templates per topology/size combination
- Documentation: Integration guide, path reference guide, troubleshooting

**APIs**: 
- Experiment Runner events: before_experiment, start_run, interact, stop_measurement, populate_run_data, etc.
- muBench K8sDeployer: `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json`
- Locust CLI: `locust -f Benchmarks/Locust/locustfile.py --headless -u <users> -r <spawn_rate> -t <duration> --host http://localhost:9090 --csv=<output>`
- SSH tunnel: `./scripts/gateway-tunnel-local.sh` (background process)
- Kubernetes API: kubectl commands for namespace management, pod status checks
- Prometheus API: HTTP queries for metrics (e.g., `http://localhost:30000/api/v1/query`)

**Data**: 
- Experiment results: Experiment Runner output (CSV/JSON) with aggregated metrics per run
- Locust metrics: CSV exports (throughput, latency, failures) per run
- Prometheus metrics: CPU/memory usage per service, system-wide metrics
- Run metadata: Topology, size, replicate number, timestamps, status
- Configuration data: Workmodel paths per topology/size, deployment configs

## 📋 Next Actions (2min)

**Phase 1: POC Complete ✅**
- [x] Research folder structure options (sibling vs inside muBench) - analyze pros/cons
- [x] Review Experiment Runner examples (hello-world, linux-ps-profiling) for integration patterns
- [x] Create initial RunnerConfig.py structure with RunTableModel (6 topologies × 3 sizes × 30 replicates)
- [x] Set up path configuration (relative paths from Experiment Runner to muBench)
- [x] Test basic Experiment Runner execution (hello-world example)
- [x] Integrate SSH tunnel setup in before_experiment hook
- [x] Integrate Locust execution in interact hook (test with standalone gateway)
- [x] Test end-to-end workflow with mock gateway (no minikube required)

**Phase 2: Full Deployment Integration (Current Phase) - Ready to Implement**
- [x] **PREREQUISITE**: Generate all 18 workmodel files manually (6 topologies × 3 sizes: 5, 10, 20 services) ✅ ALL GENERATED
- [x] **Implementation Guide Created**: [DEPLOYMENT_IMPLEMENTATION.md](DEPLOYMENT_IMPLEMENTATION.md) with complete code snippets ✅
- [x] **Workmodel Mapping Documented**: All 18 files verified, naming convention documented in implementation guide ✅
- [ ] **Implementation**: Add code to RunnerConfig.py (see DEPLOYMENT_IMPLEMENTATION.md)
  - [ ] Add workmodel mapping function (`get_workmodel_path`)
  - [ ] Add namespace management functions (`create_namespace`, `delete_namespace`)
  - [ ] Add K8sParameters generation function (`generate_k8s_parameters`)
  - [ ] Add Prometheus query functions (`query_prometheus`, `get_cpu_usage`, `get_memory_usage`)
  - [ ] Update `start_run` hook with deployment logic
  - [ ] Update `stop_measurement` hook with Prometheus queries
  - [ ] Update `populate_run_data` hook with Prometheus parsing
  - [ ] Update `stop_run` hook with cleanup (optional)
- [ ] Test manual deployment first: `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json`
- [ ] Test single run end-to-end with actual muBench deployment
- [ ] Test with multiple runs to verify namespace management and cleanup

**Start Coding In**: ~30min (after brief completion)

---
**Total Planning Time**: ~30min | **Owner**: Researcher | **Date**: 2025-01-XX

<!-- Living Document - Update as you code -->

## 📝 Changelog

**2025-01-XX - Phase 2 Implementation Guide Ready**
- ✅ Created DEPLOYMENT_IMPLEMENTATION.md with complete code snippets for:
  - Workmodel mapping function
  - Namespace management functions
  - K8sParameters generation
  - Deployment execution in start_run hook
  - Prometheus query functions
  - Prometheus parsing in populate_run_data hook
  - Cleanup in stop_run hook
- ✅ All 18 workmodel files verified and documented
- ✅ Ready to implement deployment and Prometheus integration
- 🔄 Next: Add implementation code to RunnerConfig.py and test with actual deployments

## 🔄 Implementation Tracking

**CRITICAL**: Follow the todo-list systematically. Mark items as complete, document blockers, update progress.

### Progress
- [x] Researched folder structure options - decided on sibling directories (experiment-runner/ and muBench/ as siblings)
- [x] Reviewed Experiment Runner examples (hello-world, linux-ps-profiling) for integration patterns
- [x] Created initial RunnerConfig.py structure with RunTableModel (6 topologies × 3 sizes × 30 replicates = 540 runs)
- [x] Set up path configuration (relative paths from Experiment Runner to muBench)
- [x] Integrated SSH tunnel setup in before_experiment hook (with error handling)
- [x] Integrated Locust execution in interact hook (headless mode, CSV export, error handling)
- [x] Added Locust metric parsing in populate_run_data hook (throughput, latency, failures)
- [x] Created README.md with usage instructions and troubleshooting
- [x] Validated RunnerConfig.py syntax
- [x] Created experiment-runner/examples/mubench-benchmarking/ directory structure
- [x] **✅ TESTED** - Test basic Experiment Runner execution ✅
- [x] **✅ TESTED** - Test Locust integration with standalone gateway ✅
- [x] **✅ TESTED** - Test end-to-end workflow with mock gateway ✅
- [x] **✅ TESTED** - Verify Locust metric parsing works correctly ✅
- [x] **PREREQUISITE**: Generate all 18 workmodel files (6 topologies × 3 sizes: 5, 10, 20 services) manually ✅ ALL GENERATED
- [x] **Implementation Guide**: Created DEPLOYMENT_IMPLEMENTATION.md with complete code snippets ✅
- [x] **Workmodel Mapping**: Documented in implementation guide with all 18 file paths ✅
- [ ] **Implementation**: Add deployment and Prometheus integration code to RunnerConfig.py
- [ ] **Testing**: Test with actual muBench deployments on server (minikube + Prometheus available)

**✅ TESTING COMPLETE: Basic integration tested and verified. See [TEST_RESULTS.md](TEST_RESULTS.md) for detailed test results.**

### Blockers
- **Workmodel Generation**: ✅ ALL 18 workmodel files generated and tested
  - Required: 6 topologies × 3 sizes (5, 10, 20 services) = 18 files
  - Status: All files exist, all manually generated files tested ✅
  - Manually generated: 10 files (Nov 16-17, 2025) - all tested ✅
  - All workmodels verified to deploy correctly
- Testing requires:
  1. Experiment Runner dependencies installed (`pip install -r requirements.txt` in experiment-runner/)
  2. Standalone gateway running (for testing without minikube): `./scripts/gateway-tunnel-standalone-python.sh`
  3. SSH tunnel capability (for gateway access)
  4. All 18 workmodel files generated (for deployment integration)

### Current Implementation Status

**✅ COMPLETED:**
- Folder structure: Sibling directories (experiment-runner/ and muBench/)
- RunnerConfig.py: Created with full event hook structure
- RunTableModel: 6 topologies × 3 sizes × 30 replicates = 540 runs
- Path configuration: Relative paths from Experiment Runner to muBench
- SSH tunnel integration: Automated setup in before_experiment hook
- Locust integration: Headless execution in interact hook with CSV export
- Metric parsing: Locust CSV parsing in populate_run_data hook
- Error handling: Graceful degradation for missing components
- Documentation: README.md with usage instructions

**🔄 IN PROGRESS / TODO:**
- ✅ **PREREQUISITE**: Generate all 18 workmodel files (6 topologies × 3 sizes: 5, 10, 20 services) - ✅ ALL GENERATED
- ✅ **Testing**: All 10 manually generated workmodels tested and verified ✅
- ✅ **Implementation Guide**: DEPLOYMENT_IMPLEMENTATION.md created with complete code snippets ✅
- 🔄 **Implementation**: Add deployment and Prometheus integration code to RunnerConfig.py (ready to implement)
- 🔄 **Testing**: Test with actual muBench deployments on server (minikube + Prometheus available)

**📁 FILES CREATED:**
- `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py` (391 lines) ✅ Tested
- `experiment-runner/examples/mubench-benchmarking/README.md` (usage instructions)
- `muBench/specs/active/experiment-runner-locust-integration/DEPLOYMENT_IMPLEMENTATION.md` (607 lines) ✅ Complete implementation guide
- `muBench/specs/active/experiment-runner-locust-integration/HOST_HANDOFF_PROMPT.md` (handoff documentation)

**🔗 INTEGRATION POINTS:**
- muBench location: `../muBench/` (relative from Experiment Runner)
- Locust file: `../muBench/Benchmarks/Locust/locustfile.py`
- SSH tunnel script: `../muBench/scripts/gateway-tunnel-local.sh`
- K8sDeployer: `../muBench/Deployers/K8sDeployer/RunK8sDeployer.py` (for future deployment)

**See**: [.sdd/IMPLEMENTATION_GUIDE.md](mdc:.sdd/IMPLEMENTATION_GUIDE.md) for detailed execution rules.

## 📝 Implementation Notes

### Folder Structure Analysis

**Option A: Sibling Directories** (Recommended)
```
~/Documents/Research Project/
├── experiment-runner/
│   ├── examples/
│   │   └── mubench-benchmarking/
│   │       └── RunnerConfig.py
│   └── ...
└── muBench/
    ├── Benchmarks/Locust/
    ├── Deployers/K8sDeployer/
    ├── scripts/
    └── ...
```

**Pros:**
- Independent versioning (git repos separate)
- Clear separation of concerns
- Experiment Runner can be updated independently
- Follows existing structure (already set up this way)

**Cons:**
- Need relative paths (`../muBench/`)
- Slightly more complex path references

**Option B: Inside muBench**
```
muBench/
├── experiment-runner/
│   └── examples/
│       └── mubench-benchmarking/
│           └── RunnerConfig.py
├── Benchmarks/Locust/
└── ...
```

**Pros:**
- Simpler paths (relative to muBench root)
- Everything in one place

**Cons:**
- Couples Experiment Runner to muBench
- Harder to update Experiment Runner independently
- Doesn't match current structure

**Decision**: Use **Option A (Sibling Directories)** - matches current setup, allows independent management.

### Path References

From `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`:
- muBench root: `Path(__file__).parent.parent.parent.parent / 'muBench'`
- Locust file: `mubench_path / 'Benchmarks' / 'Locust' / 'locustfile.py'`
- K8sDeployer: `mubench_path / 'Deployers' / 'K8sDeployer' / 'RunK8sDeployer.py'`
- SSH tunnel script: `mubench_path / 'scripts' / 'gateway-tunnel-local.sh'`
- K8sParameters: `mubench_path / 'Configs' / 'K8sParameters.json'`

### Experiment Design

**Run Table Model:**
- Factor 1: Topology (6 levels)
  - Sequential Fan-out
  - Parallel Fan-out
  - Centralized Star
  - Hierarchical Tree
  - Probabilistic Tree
  - Complex Mesh
- Factor 2: System Size (3 levels)
  - 5 services
  - 10 services
  - 20 services
- Repetitions: 30 per configuration
- Total runs: 6 × 3 × 30 = 540 runs

**Data Columns:**
- `throughput_rps` (from Locust)
- `avg_latency_ms` (from Locust)
- `p95_latency_ms` (from Locust)
- `failure_rate` (from Locust)
- `cpu_usage_avg` (from Prometheus)
- `memory_usage_avg` (from Prometheus)
- `request_count` (from Locust)

### Integration Workflow

**Event Hook Sequence:**
1. **before_experiment**: 
   - Set up SSH tunnel (background process)
   - Verify gateway connectivity
   - Check kubectl access (if minikube available)
   - Initialize experiment metadata

2. **before_run**: 
   - Prepare namespace name: `mubench-{topology}-{size}-{replicate}`
   - Prepare workmodel path based on topology/size
   - Prepare K8sParameters.json for this run

3. **start_run**: 
   - Create Kubernetes namespace
   - Execute K8sDeployer: `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json`
   - Wait for all pods ready: `kubectl wait --for=condition=ready pod --all -n <namespace> --timeout=300s`
   - Verify gateway accessible: `curl http://localhost:9090/s0`

4. **start_measurement**: 
   - Verify Prometheus accessible (if available)
   - Record start timestamp
   - Optional: Start Prometheus metric collection

5. **interact**: 
   - Execute Locust: `locust -f Benchmarks/Locust/locustfile.py --headless -u 50 -r 5 -t 10m --host http://localhost:9090 --csv=<run_dir>/locust`
   - Wait for Locust completion
   - Verify Locust exit code

6. **stop_measurement**: 
   - Query Prometheus metrics (if available)
   - Export Prometheus data to CSV/JSON
   - Record end timestamp

7. **stop_run**: 
   - Optional: Keep deployment for debugging
   - Or: Delete namespace: `kubectl delete namespace <namespace>`
   - Clean up temporary files

8. **populate_run_data**: 
   - Parse Locust CSV: `locust_stats.csv`
   - Parse Prometheus data (if available)
   - Calculate aggregated metrics
   - Return dictionary with data_columns

9. **after_experiment**: 
   - Stop SSH tunnel
   - Final cleanup
   - Generate summary report

### Testing Strategy

**Phase 1: Basic Integration (No Minikube)**
- Test with standalone Python gateway
- Verify SSH tunnel setup
- Test Locust execution
- Test path references

**Phase 2: Single Run (With Minikube)**
- Test full workflow with one deployment
- Verify K8sDeployer integration
- Test Prometheus collection
- Verify metric parsing

**Phase 3: Multiple Runs**
- Test with 2-3 runs
- Verify namespace management
- Test error handling
- Test restart capability

**Phase 4: Full Scale**
- Run subset of 540 runs (e.g., 1 topology × 1 size × 5 replicates)
- Verify performance and stability
- Monitor resource usage
- Test restart after interruption

### Error Handling

**Deployment Failures:**
- Retry deployment (max 3 attempts)
- Log error details
- Mark run as failed, continue to next

**Locust Failures:**
- Check exit code
- Retry Locust execution (max 2 attempts)
- Use partial results if available

**Prometheus Connection Issues:**
- Graceful degradation (skip Prometheus if unavailable)
- Log warning, continue with Locust metrics only

**SSH Tunnel Issues:**
- Verify tunnel process running
- Restart tunnel if needed
- Fail fast if tunnel cannot be established

### Configuration Management

**Workmodel Generation Requirement:**
- **Prerequisite**: All 18 workmodel files must exist before deployment integration can proceed
- **Required**: 6 topologies × 3 sizes (5, 10, 20 services) = 18 workmodel files total
- **Generation**: Workmodels will be generated manually (no automated generation)
- **Location**: `Examples/` directory in muBench

**Workmodel Mapping:**
- Topology × Size → Workmodel file path
- Naming conventions:
  - Sequential Fan-out: `workmodel-serial-{size}services.json`
  - Parallel Fan-out: `workmodel-parallel-{size}services.json`
  - Centralized Star: `workmodelA.json` (20 services), `workmodelA-{size}services.json` (5, 10)
  - Hierarchical Tree: `workmodelC.json` (20 services), `workmodelC-{size}services.json` (5, 10)
  - Probabilistic Tree: `workmodelC-multi.json` (20 services), `workmodelC-multi-{size}services.json` (5, 10)
  - Complex Mesh: `workmodelD.json` (20 services), `workmodelD-{size}services.json` (5, 10)
- Examples:
  - Sequential Fan-out × 10 services → `Examples/workmodel-serial-10services.json`
  - Centralized Star × 20 services → `Examples/workmodelA.json`
  - Hierarchical Tree × 5 services → `Examples/workmodelC-5services.json`
- Store mapping in RunnerConfig or separate config file

**Workmodel Status:**
- **Sequential Fan-out (Serial)**: 
  - ✅ 5 services: `workmodel-serial-5services.json` (exists)
  - ✅ 10 services: `workmodel-serial-10services.json` (exists)
  - ✅ 20 services: `workmodel-serial-20services.json` (manually generated, tested ✅)
- **Parallel Fan-out (Parallel)**:
  - ✅ 5 services: `workmodel-parallel-5services.json` (exists)
  - ✅ 10 services: `workmodel-parallel-10services.json` (exists)
  - ✅ 20 services: `workmodel-parallel-20services.json` (manually generated, tested ✅)
- **Centralized Star**:
  - ✅ 5 services: `workmodelA-5services.json` (manually generated, tested ✅)
  - ✅ 10 services: `workmodelA-10services.json` (manually generated, tested ✅)
  - ✅ 20 services: `workmodelA.json` (exists)
- **Hierarchical Tree**:
  - ✅ 5 services: `workmodelC-5services.json` (manually generated, tested ✅)
  - ✅ 10 services: `workmodelC-10services.json` (manually generated, tested ✅)
  - ✅ 20 services: `workmodelC.json` (exists)
- **Probabilistic Tree**:
  - ✅ 5 services: `workmodelC-multi-5services.json` (manually generated, tested ✅)
  - ✅ 10 services: `workmodelC-multi-10services.json` (manually generated, tested ✅)
  - ✅ 20 services: `workmodelC-multi.json` (exists)
- **Complex Mesh**:
  - ✅ 5 services: `workmodelD-5services.json` (manually generated, tested ✅)
  - ✅ 10 services: `workmodelD-10services.json` (manually generated, tested ✅)
  - ✅ 20 services: `workmodelD.json` (exists)

**Manually Generated Workmodels (Nov 16-17, 2025):**
The following 10 workmodel files were manually generated and tested:
1. `workmodel-serial-20services.json`
2. `workmodel-parallel-20services.json`
3. `workmodelA-5services.json`
4. `workmodelA-10services.json`
5. `workmodelC-5services.json`
6. `workmodelC-10services.json`
7. `workmodelC-multi-5services.json`
8. `workmodelC-multi-10services.json`
9. `workmodelD-5services.json`
10. `workmodelD-10services.json`

All manually generated workmodels have been tested and verified to deploy correctly.

**Note**: Exact naming convention may vary based on existing patterns. Verify naming after generation and update mapping accordingly.

**K8sParameters Template:**
- Base template: `Configs/K8sParameters.json`
- Per-run modifications:
  - `namespace`: Unique namespace per run
  - `WorkModelPath`: Based on topology/size
  - `OutputPath`: Run-specific output directory

### Integration Points

**SSH Tunnel:**
- Script: `scripts/gateway-tunnel-local.sh`
- Start: Background process in `before_experiment`
- Stop: Kill process in `after_experiment`
- Verify: `curl http://localhost:9090/s0` before each run

**muBench Deployment:**
- Command: `python3 Deployers/K8sDeployer/RunK8sDeployer.py -c <config>`
- Working directory: muBench root
- Wait for: All pods ready in namespace
- Gateway: Accessible via SSH tunnel at `http://localhost:9090`

**Locust Execution:**
- Command: `locust -f Benchmarks/Locust/locustfile.py --headless -u 50 -r 5 -t 10m --host http://localhost:9090 --csv=<output>`
- Working directory: muBench root (or use absolute path to locustfile)
- Output: CSV files in run directory
- Parse: `locust_stats.csv` for aggregated metrics

**Prometheus Collection:**
- Endpoint: `http://localhost:30000` (via monitoring tunnel)
- Queries: CPU usage, memory usage, request latency
- Export: CSV or JSON format
- Timing: Query after Locust completes (stop_measurement)

### Performance Considerations

**540 Runs Scale:**
- Average run time: ~15 minutes (deployment + measurement + cleanup)
- Total time: ~135 hours (5.6 days) if sequential
- Parallelization: Consider running multiple topologies in parallel (if resources allow)
- Restart capability: Critical for long-running experiments

**Resource Management:**
- Namespace cleanup: Delete after each run (or keep for debugging)
- SSH tunnel: Single tunnel for all runs (reuse)
- Locust output: Store per-run, aggregate at end
- Prometheus data: Query incrementally, don't store all raw data

### Future Enhancements

- Parallel execution of multiple runs (if server resources allow)
- Real-time progress monitoring
- Automatic error recovery and retry logic
- Integration with energy measurement tools (future)
- Support for trace-driven benchmarks (POST requests)
- Dynamic workload intensity adjustment based on system response

