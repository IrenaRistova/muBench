# Handoff: Experiment Runner + Locust Integration

**For New Chat Session**

## Quick Context

I'm working on integrating Experiment Runner with Locust to orchestrate muBench Phase 3 benchmarking experiments. The basic structure is complete, but **testing is still needed**.

## Current Status

**✅ COMPLETED:**
- RunnerConfig.py created with full event hook structure
- RunTableModel: 6 topologies × 3 sizes × 30 replicates = 540 runs
- SSH tunnel integration (before_experiment hook)
- Locust execution integration (interact hook)
- Locust metric parsing (populate_run_data hook)
- Path configuration (relative paths from Experiment Runner to muBench)
- Documentation (README.md, feature-brief.md, CURRENT_STATUS.md)

**⚠️ TESTING REQUIRED:**
- Basic Experiment Runner execution (not yet tested)
- Locust integration (not yet tested)
- End-to-end workflow with standalone gateway (not yet tested)
- Metric parsing (not yet tested)

**🔄 PENDING:**
- muBench deployment integration (start_run hook) - requires minikube
- Prometheus metric collection (stop_measurement hook) - requires Prometheus

## Folder Structure

```
~/Documents/Research Project/
├── experiment-runner/
│   └── examples/
│       └── mubench-benchmarking/
│           ├── RunnerConfig.py      # ✅ Created (371 lines)
│           └── README.md            # ✅ Created
└── muBench/
    ├── Benchmarks/Locust/            # ✅ Locust integrated
    ├── specs/active/
    │   └── experiment-runner-locust-integration/
    │       ├── feature-brief.md     # ✅ Complete
    │       ├── CURRENT_STATUS.md    # ✅ Status doc
    │       └── HANDOFF.md           # This file
    └── ...
```

## What to Tell New Chat Session

**Copy and paste this:**

---

I'm continuing work on the **experiment-runner-locust-integration** feature. The basic structure is complete, but **I need to test everything that was done with Experiment Runner**.

**Current Status:**
- ✅ RunnerConfig.py created at `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
- ✅ SSH tunnel and Locust integration implemented
- ✅ Locust metric parsing implemented
- ⚠️ **TESTING REQUIRED** - Nothing has been tested yet

**What I need:**
1. Test basic Experiment Runner execution
2. Test Locust integration with standalone gateway
3. Test end-to-end workflow
4. Verify metric parsing works correctly

**Files to check:**
- `specs/active/experiment-runner-locust-integration/feature-brief.md` - Complete implementation details
- `specs/active/experiment-runner-locust-integration/CURRENT_STATUS.md` - Current status
- `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py` - Main config file
- `experiment-runner/examples/mubench-benchmarking/README.md` - Usage instructions

**Context:**
- Experiment Runner is in sibling directory to muBench
- Locust is already integrated and working
- We can test with standalone gateway (no minikube required)
- Need to verify everything works before adding deployment/Prometheus integration

**Next steps:**
1. Test Experiment Runner execution
2. Test with standalone gateway
3. Verify Locust metrics are parsed correctly
4. Then add deployment and Prometheus integration

---

## Key Files

**Implementation:**
- `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py` - Main config (371 lines)
- `experiment-runner/examples/mubench-benchmarking/README.md` - Usage instructions

**Documentation:**
- `specs/active/experiment-runner-locust-integration/feature-brief.md` - Complete brief
- `specs/active/experiment-runner-locust-integration/CURRENT_STATUS.md` - Status summary
- `specs/active/experiment-runner-locust-integration/HANDOFF.md` - This file

**Related:**
- `specs/active/locust-workload-setup/feature-brief.md` - Locust integration (complete)
- `specs/00-overview.md` - Project overview (updated with Experiment Runner status)
- `specs/index.md` - Feature index (updated)

## Testing Instructions

### Test 1: Basic Execution

```bash
cd ~/Documents/Research\ Project/experiment-runner
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
```

**Expected:** Experiment Runner should start, create RunTableModel, begin experiment

### Test 2: With Standalone Gateway

1. **Start standalone gateway** (separate terminal):
   ```bash
   cd ~/Documents/Research\ Project/muBench
   ./scripts/gateway-tunnel-standalone-python.sh
   ```

2. **Run Experiment Runner**:
   ```bash
   cd ~/Documents/Research\ Project/experiment-runner
   python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
   ```

**Expected:**
- SSH tunnel setup (or use existing)
- Skip deployment (no minikube)
- Execute Locust workload
- Parse Locust metrics
- Generate results

### Test 3: Verify Results

Check results directory:
```bash
ls -la ~/Documents/Research\ Project/experiment-runner/examples/mubench-benchmarking/experiments/
```

**Expected:**
- `run_table.csv` - Aggregated results
- `run_0_repetition_0/` - Individual run results
  - `locust/results_stats.csv` - Locust metrics
  - `measurement_start.txt` - Timestamps

## Known Issues / TODOs

1. **muBench Deployment** - Not implemented yet (TODO in start_run hook)
2. **Prometheus Collection** - Not implemented yet (TODO in stop_measurement hook)
3. **Namespace Management** - Not implemented yet
4. **Error Handling** - Basic error handling, needs enhancement
5. **Testing** - ⚠️ **NOT TESTED YET** - Need to verify everything works

## Dependencies

- Experiment Runner: `experiment-runner/` directory
- Locust: `muBench/venv/bin/locust` (installed)
- muBench: Sibling directory to experiment-runner
- Standalone gateway: `muBench/scripts/gateway-tunnel-standalone-python.sh` (for testing)

## Integration Points

**From Experiment Runner:**
- muBench: `../muBench/`
- Locust file: `../muBench/Benchmarks/Locust/locustfile.py`
- SSH tunnel: `../muBench/scripts/gateway-tunnel-local.sh`
- K8sDeployer: `../muBench/Deployers/K8sDeployer/RunK8sDeployer.py` (future)

## Next Steps After Testing

1. ✅ Test basic execution
2. ✅ Test with standalone gateway
3. ✅ Verify metric parsing
4. 🔄 Add muBench deployment integration (when minikube available)
5. 🔄 Add Prometheus metric collection (when Prometheus available)
6. 🔄 Test with single run, then scale to multiple runs

## Important Notes

- **Testing is critical** - Nothing has been tested yet
- Can test with standalone gateway (no minikube required)
- Deployment integration can be added after testing
- Prometheus integration can be added after testing
- Path references use relative paths (sibling directories)

