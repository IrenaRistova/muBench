# Test Results: Experiment Runner + Locust Integration

**Date:** 2025-11-07  
**Status:** ✅ Basic Integration Verified

## Test Summary

Successfully tested Experiment Runner integration with Locust using standalone gateway. All core functionality verified.

## What Was Tested

### ✅ 1. Configuration Loading
- **Test:** RunnerConfig.py loads and instantiates correctly
- **Result:** ✅ PASS - Config loads successfully, all paths resolve correctly
- **Details:**
  - muBench directory: `/home/irena/Documents/Research Project/muBench`
  - Locust file: Found and accessible
  - SSH tunnel script: Found and accessible
  - K8sDeployer: Found (for future deployment)

### ✅ 2. Experiment Runner Execution
- **Test:** Experiment Runner can execute the config
- **Result:** ✅ PASS - Experiment Runner starts and executes workflow
- **Details:**
  - RunTableModel created: 6 topologies × 3 sizes × 1 repetition = 18 runs (reduced for testing)
  - All event hooks called correctly:
    - `before_experiment` ✓
    - `before_run` ✓
    - `start_run` ✓
    - `start_measurement` ✓
    - `interact` ✓
    - `stop_measurement` ✓
    - `stop_run` ✓
    - `populate_run_data` ✓

### ✅ 3. Gateway Connectivity
- **Test:** Gateway accessible via standalone gateway
- **Result:** ✅ PASS - Gateway accessible at `http://localhost:9090`
- **Details:**
  - Standalone gateway started: `gateway-tunnel-standalone-python.sh`
  - Gateway responds to GET requests: HTTP 200
  - Gateway accessible from Experiment Runner

### ✅ 4. Locust Execution
- **Test:** Locust executes in headless mode
- **Result:** ✅ PASS - Locust executes and generates load
- **Details:**
  - Locust command: Executes correctly
  - CSV output: Created in run directory (`results_stats.csv`)
  - HTML output: Created (`results.html`)
  - Exit code: 1 (expected - see limitations below)

### ✅ 5. CSV File Creation
- **Test:** Locust CSV files are created correctly
- **Result:** ✅ PASS - CSV files created with metrics
- **Details:**
  - `results_stats.csv`: Contains aggregated metrics
  - `results_stats_history.csv`: Time-series data
  - `results_failures.csv`: Failure details
  - Metrics include: Request Count, Failure Count, Response Times, Requests/s

### ✅ 6. Metric Parsing Logic
- **Test:** Metric parsing in `populate_run_data` hook
- **Result:** ✅ PASS - Parsing logic fixed and verified
- **Details:**
  - Fixed: Changed from `row['Type'] == 'Aggregated'` to `row.get('Name') == 'Aggregated'`
  - CSV structure: Aggregated row has empty Type column, Name column contains "Aggregated"
  - Parsed metrics:
    - `throughput_rps` from "Requests/s"
    - `avg_latency_ms` from "Average Response Time"
    - `p95_latency_ms` from "95%"
    - `failure_rate` calculated from Failure Count / Request Count
    - `request_count` from "Request Count"

## Known Limitations (Expected Behavior)

### 1. Locust Exit Code 1
- **Status:** Expected behavior
- **Reason:** Standalone mock gateway only implements GET requests
- **Details:**
  - GET requests: ✅ Work correctly (HTTP 200)
  - POST requests: ❌ Fail with 501 (Not Implemented) - expected
  - Locust exits with code 1 when there are failures (normal behavior)
- **Solution:** Using `-c StochasticBenchmarkUser` to use only GET requests for testing

### 2. POST Request Failures
- **Status:** Expected limitation of standalone gateway
- **Details:**
  - Standalone gateway (`gateway-tunnel-standalone-python.sh`) only implements GET
  - POST requests return 501 (Not Implemented)
  - This is normal for testing - real muBench deployment will support POST
- **Reference:** See `specs/active/locust-workload-setup/feature-brief.md` and `Benchmarks/Locust/RESULTS_ANALYSIS.md`

## Issues Fixed During Testing

### 1. Missing `requests` Module
- **Issue:** `ModuleNotFoundError: No module named 'requests'`
- **Fix:** Installed `requests` in Experiment Runner venv
- **Status:** ✅ Fixed

### 2. Incorrect Context Attribute
- **Issue:** `AttributeError: 'RunnerContext' object has no attribute 'run_id'`
- **Fix:** Changed `context.run_id` to `context.run_nr`
- **Status:** ✅ Fixed

### 3. CSV Parsing Logic
- **Issue:** Metrics not being parsed from CSV (empty Type column for Aggregated row)
- **Fix:** Changed parsing to check `row.get('Name') == 'Aggregated'` instead of `row.get('Type') == 'Aggregated'`
- **Status:** ✅ Fixed

### 4. Locust User Class Selection
- **Issue:** Both GET and POST user classes running, causing POST failures
- **Fix:** Added `-c StochasticBenchmarkUser` to Locust command to use only GET requests
- **Status:** ✅ Fixed

## Test Configuration

### Experiment Setup
- **Topologies:** 6 (sequential_fanout, parallel_fanout, centralized_star, hierarchical_tree, probabilistic_tree, complex_mesh)
- **System Sizes:** 3 (5, 10, 15 services)
- **Repetitions:** 1 (reduced from 30 for testing)
- **Total Runs:** 18 (reduced from 540 for testing)

### Locust Configuration (Testing)
- **Users:** 10 (reduced from 50 for testing)
- **Spawn Rate:** 2 (reduced from 5 for testing)
- **Duration:** 1m (reduced from 10m for testing)
- **User Class:** StochasticBenchmarkUser (GET only)

### Production Configuration (Not Tested)
- **Users:** 50
- **Spawn Rate:** 5
- **Duration:** 10m (2 min warm-up + 8 min measurement)
- **Repetitions:** 30 per configuration
- **Total Runs:** 540 (6 topologies × 3 sizes × 30 repetitions)

## Verification Checklist

- [x] RunnerConfig.py loads successfully
- [x] Experiment Runner executes workflow
- [x] Gateway accessible
- [x] Locust executes in headless mode
- [x] CSV files created with metrics
- [x] Metric parsing logic works
- [x] Event hooks called correctly
- [x] Error handling works (graceful degradation for expected failures)
- [ ] Full experiment run (540 runs) - pending
- [ ] muBench deployment integration - pending (requires minikube)
- [ ] Prometheus metric collection - pending (requires Prometheus)

## Next Steps

1. **For Full Testing:**
   - Restore production configuration (50 users, 10m duration, 30 repetitions)
   - Test with real muBench deployment (when minikube available)
   - Test Prometheus metric collection (when Prometheus available)

2. **For Production Use:**
   - Deploy muBench application via K8sDeployer
   - Run full experiment (540 runs)
   - Collect Prometheus metrics
   - Analyze results

## Files Modified During Testing

1. `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
   - Fixed `context.run_id` → `context.run_nr`
   - Fixed CSV parsing logic (check Name instead of Type)
   - Added `-c StochasticBenchmarkUser` to Locust command
   - Improved error messages for expected failures
   - Reduced test parameters (users, duration, repetitions)

## Test Environment

- **OS:** Linux 6.14.0-35-generic
- **Python:** 3.12.3
- **Experiment Runner:** Latest (muBench-Irena branch)
- **Locust:** 2.42.2 (in muBench venv)
- **Gateway:** Standalone Python mock gateway (`gateway-tunnel-standalone-python.sh`)

## Conclusion

✅ **Basic integration verified and working correctly!**

The Experiment Runner integration with Locust is functional and ready for testing with real muBench deployments. All core functionality works:
- Configuration loads correctly
- Experiment workflow executes
- Locust generates load
- Metrics are collected and parsed
- Error handling works gracefully

The only limitations are expected (standalone gateway limitations) and will be resolved when using real muBench deployments.



