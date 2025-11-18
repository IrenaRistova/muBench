# Current Status: Experiment Runner + Locust Integration

**Last Updated:** 2025-01-XX  
**Status:** ✅ **FULLY WORKING** - All components tested and functional

## Quick Summary

Experiment Runner integration with muBench deployment is **fully implemented and working**. The complete workflow is functional:
- ✅ Namespace management (create/delete per run)
- ✅ muBench deployment via K8sDeployer
- ✅ Pod readiness checks
- ✅ Gateway port-forwarding per namespace
- ✅ Locust workload execution
- ✅ Metric parsing and CSV generation
- ✅ Prometheus queries (working when tunnels are set up correctly)

## What's Done ✅

1. **Folder Structure**: Decided on sibling directories (experiment-runner/ and muBench/)
2. **RunnerConfig.py**: Created with full event hook structure
   - Location: `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
   - RunTableModel: 6 topologies × 3 sizes × 1 repetition = 18 runs (testing), 30 for full experiment
3. **Path Configuration**: Relative paths from Experiment Runner to muBench
4. **SSH Tunnel Integration**: Automated setup in `before_experiment` hook
5. **Locust Integration**: Headless execution in `interact` hook with CSV export
6. **Metric Parsing**: Locust CSV parsing in `populate_run_data` hook
7. **Deployment Integration**: ✅ **FULLY IMPLEMENTED**
   - Namespace creation/deletion via SSH to server
   - K8sParameters.json generation and transfer to server
   - K8sDeployer execution via SSH
   - Pod readiness checks
   - Gateway port-forwarding per namespace
8. **Prometheus Integration**: ✅ **WORKING** - Queries succeed when SSH tunnels are properly configured
9. **Documentation**: README.md created with usage instructions

## What's Tested ✅

1. **✅ Basic Execution**: Experiment Runner executes config successfully
2. **✅ Locust Integration**: Locust executes in headless mode, generates load
3. **✅ Metric Parsing**: Locust CSV parsing works correctly
4. **✅ End-to-End Workflow**: Complete workflow tested with standalone gateway
5. **✅ Gateway Connectivity**: Standalone gateway accessible and working
6. **✅ CSV File Creation**: Metrics exported correctly
7. **✅ Full Deployment Workflow**: **TESTED AND WORKING**
   - Namespace creation/deletion working
   - K8sDeployer successfully deploying muBench applications
   - Pods becoming ready correctly
   - Gateway port-forwarding working per namespace
   - Locust executing against deployed services
   - Metrics being collected (RPS, latency)
   - Multiple runs completing successfully (18 runs tested)

**Test Results:** See [TEST_RESULTS.md](TEST_RESULTS.md) for detailed test results.

**Current Test Status:** 
- ✅ **18 runs completed successfully** with full deployment
- ✅ Locust metrics collected: RPS (1.84-4.52), latency (4.5-1409ms)
- ✅ Prometheus metrics collected: CPU (0.001-0.003), Memory (24-46 MB)
- ✅ All 6 topologies × 3 sizes tested successfully

## What's Pending 🔄

1. **Full Scale Testing**: Test with full experiment (540 runs, 10m duration per run)
   - Current: 18 runs with 5s duration (testing) ✅
   - Full: 540 runs (18 configs × 30 replicates) with 10m duration
2. **Error Handling**: Enhanced retry logic and recovery for deployment failures
3. **Namespace Cleanup**: Enable automatic namespace deletion after runs (currently disabled for debugging)

## Documentation

- **[EXPERIMENT_RUN_GUIDE.md](EXPERIMENT_RUN_GUIDE.md)** - Complete step-by-step guide for running experiments ✅ **NEW**
- **[DEPLOYMENT_IMPLEMENTATION.md](DEPLOYMENT_IMPLEMENTATION.md)** - Implementation code snippets
- **[QUICK_START.md](QUICK_START.md)** - Quick reference for running experiments
- **[CLEANUP_SERVER.md](CLEANUP_SERVER.md)** - Server cleanup guide

## Files Created

```
experiment-runner/examples/mubench-benchmarking/
├── RunnerConfig.py          # Main config (380 lines) ✅ Tested
└── README.md                # Usage instructions

muBench/specs/active/experiment-runner-locust-integration/
├── feature-brief.md              # Complete implementation details
├── CURRENT_STATUS.md              # This file (status summary)
├── HANDOFF.md                     # Handoff documentation
├── DEVELOPMENT_WORKFLOW.md        # Multi-repository workflow guide
├── TEST_RESULTS.md                # Detailed test results ✅
├── DEPLOYMENT_IMPLEMENTATION.md   # Complete code snippets for Phase 2 ✅ New
└── HOST_HANDOFF_PROMPT.md         # Handoff prompt for host machine ✅ New
```

## Integration Points

**From Experiment Runner location:**
- muBench directory: `../muBench/`
- Locust file: `../muBench/Benchmarks/Locust/locustfile.py`
- SSH tunnel script: `../muBench/scripts/gateway-tunnel-local.sh`
- K8sDeployer: `../muBench/Deployers/K8sDeployer/RunK8sDeployer.py`

## Testing Instructions

### Test with Standalone Gateway (No Minikube)

1. **Start standalone gateway** (in separate terminal):
   ```bash
   cd ~/Documents/Research\ Project/muBench
   ./scripts/gateway-tunnel-standalone-python.sh
   ```

2. **Run Experiment Runner** (from experiment-runner directory):
   ```bash
   cd ~/Documents/Research\ Project/experiment-runner
   python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
   ```

3. **Expected behavior**:
   - SSH tunnel setup (or use existing)
   - Skip deployment (no minikube)
   - Execute Locust workload
   - Parse Locust metrics
   - Generate results in `experiments/mubench_phase3_benchmarking/`

## Next Steps

1. **Test basic execution** - Verify Experiment Runner can run the config
2. **Test with standalone gateway** - Verify Locust execution works
3. **Add deployment integration** - When minikube available
4. **Add Prometheus collection** - When Prometheus available
5. **Scale testing** - Test with multiple runs

## Key Implementation Details

### RunTableModel Structure
- **Factor 1**: Topology (6 levels)
  - sequential_fanout, parallel_fanout, centralized_star, hierarchical_tree, probabilistic_tree, complex_mesh
- **Factor 2**: System Size (3 levels)
  - 5, 10, 15 services
- **Repetitions**: 30 per configuration
- **Total Runs**: 540

### Event Hook Implementation
- `before_experiment`: SSH tunnel setup ✅ Tested
- `start_run`: muBench deployment (TODO - requires minikube)
- `interact`: Locust execution ✅ Tested
- `stop_measurement`: Prometheus collection (TODO - requires Prometheus)
- `populate_run_data`: Metric parsing ✅ Tested

### Locust Configuration
- Users: 50
- Spawn rate: 5 per second
- Duration: 10 minutes (2 min warm-up + 8 min measurement)
- Output: CSV files in run directory

## Dependencies

- Experiment Runner: Installed in `experiment-runner/`
- Locust: Installed in `muBench/venv/`
- muBench: Located in sibling directory
- SSH tunnel: Script at `muBench/scripts/gateway-tunnel-local.sh`

## Troubleshooting

### Path Issues
- Verify muBench is sibling to experiment-runner
- Check relative paths in RunnerConfig.py
- Use absolute paths if relative paths don't work

### Locust Execution
- Verify Locust installed: `muBench/venv/bin/locust --version`
- Check locustfile exists: `muBench/Benchmarks/Locust/locustfile.py`
- Verify gateway accessible: `curl http://localhost:9090/s0`

### SSH Tunnel
- Verify tunnel script exists
- Check tunnel is running: `ps aux | grep '[s]sh -N -L.*9090'`
- Test gateway connectivity

## References

- **[EXPERIMENT_RUN_GUIDE.md](EXPERIMENT_RUN_GUIDE.md)** - Complete step-by-step guide for running experiments ✅ **START HERE**
- [Feature Brief](feature-brief.md) - Complete implementation details
- [DEPLOYMENT_IMPLEMENTATION.md](DEPLOYMENT_IMPLEMENTATION.md) - Implementation code snippets
- [QUICK_START.md](QUICK_START.md) - Quick reference
- [CLEANUP_SERVER.md](CLEANUP_SERVER.md) - Server cleanup guide
- [Experiment Runner README](../../../experiment-runner/README.md)
- [Locust Integration](../locust-workload-setup/feature-brief.md)
- [muBench Overview](../../00-overview.md)

