# locust-workload-setup Feature Brief

## 🎯 Context (2min)
**Problem**: Need automated workload generation tool for Phase 3 benchmarking experiments. Current Runner.py works but Locust provides better scalability, metric collection, and integration capabilities for automated experiment orchestration with Experiment Runner.

**Users**: Researcher running Phase 3 benchmarking experiments on host machine, needing controlled HTTP load generation against muBench gateway via SSH tunnel.

**Success**: Locust successfully installed in Python venv, locustfile.py created targeting muBench gateway (localhost:9090), headless mode working, metrics collected (throughput, latency, failures), load traffic visible in Prometheus, ready for Experiment Runner integration.

## 🔍 Quick Research (15min)
### Existing Patterns
- **Runner.py** (`Benchmarks/Runner/Runner.py`) → Greedy/periodic/file workload modes, GET requests to `{gateway}/{service}` | Reuse: Gateway access pattern, service targeting (s0, s1, etc.)
- **SSH Tunnel Setup** (`scripts/gateway-tunnel-local.sh`) → Port forwarding 9090:9090 to gl3 server | Reuse: Gateway URL pattern (http://localhost:9090)
- **Gateway Access Pattern** → `{ms_access_gateway}/{service}` where service is ingress service (typically s0) | Reuse: URL structure for Locust tasks
- **Stochastic Benchmarks** (Docs/Manual.md) → GET requests to s0 trigger random service calls per workmodel.json probabilities | Reuse: Task pattern for stochastic workload
- **Trace-Driven Benchmarks** (Docs/Manual.md) → POST requests with JSON trace body defining exact service call sequences | Reuse: Task pattern for trace-driven workload
- **Prometheus Metrics** (`ServiceCell/CellController-mp.py`) → mub_request_processing_latency_milliseconds, mub_response_size, etc. | Reuse: Metric verification approach
- **Runner Parameters** (`Configs/RunnerParameters.json`) → ingress_service, workload_type, workload_events | Reuse: Configuration pattern for workload parameters

### Tech Decision
**Approach**: Locust in Python virtual environment with headless mode execution, supporting both stochastic (GET) and trace-driven (POST) benchmark patterns, CSV/JSON metric export for analysis.

**Why**: 
- Locust is already chosen tool per project overview (specs/00-overview.md)
- Python venv provides isolated dependencies, avoids system Python conflicts
- Headless mode enables automation with Experiment Runner
- Supports both GET (stochastic) and POST (trace-driven) patterns required by muBench
- Built-in metric collection (throughput, latency, failures) with export capabilities
- Scales better than current Runner.py for high user counts
- Integrates well with existing SSH tunnel setup (localhost:9090)

**Avoid**: 
- System-wide Python installation (dependency conflicts)
- Interactive/web UI mode (not suitable for automation)
- Other load testing tools (JMeter, ab) - Locust already chosen
- Modifying existing Runner.py (Locust is separate tool for Phase 3)

## ✅ Requirements (10min)
- **Locust Installation** → Locust installed in Python virtual environment, accessible via command line, version compatible with headless mode
- **Virtual Environment Setup** → Python venv created, activated, requirements.txt with Locust dependency
- **locustfile.py Creation** → Locust test file created with User classes for stochastic (GET to s0/s1/etc.) and trace-driven (POST with JSON) patterns
- **Gateway Integration** → Locustfile targets http://localhost:9090 (via SSH tunnel), supports service endpoints (s0, s1, etc.)
- **Headless Mode Execution** → Locust runs without web UI using `--headless` flag, accepts users (-u), spawn rate (-r), duration (-t) parameters
- **Workload Patterns** → Support stochastic benchmarks (GET requests triggering workmodel.json probabilities) and trace-driven benchmarks (POST with trace JSON)
- **Metric Collection** → Collect throughput (requests/sec), latency (response time), failure rate (error count), export to CSV/JSON
- **Parameter Configuration** → Configurable users count and spawn rate for different load intensities, duration control (e.g., 2min warm-up + 8min measurement)
- **Prometheus Verification** → Verify Locust-generated traffic visible in Prometheus metrics (mub_request_processing_latency_milliseconds, etc.)
- **SSH Tunnel Integration** → Works with existing gateway-tunnel-local.sh setup, no conflicts with port 9090

## 🏗️ Implementation (5min)
**Components**: 
- Python virtual environment (venv) in project root or dedicated directory
- `locustfile.py` with User classes for stochastic and trace-driven patterns
- `requirements.txt` with Locust dependency
- Helper script or documentation for common execution patterns
- Configuration file (optional) for workload parameters (users, spawn rate, duration)

**APIs**: 
- Gateway endpoint: `http://localhost:9090` (via SSH tunnel)
- Stochastic pattern: `GET http://localhost:9090/{service}` where service is s0, s1, etc.
- Trace-driven pattern: `POST http://localhost:9090/{service}` with JSON trace body
- Prometheus metrics endpoint (for verification): Available via monitoring setup

**Data**: 
- Locust metrics export: CSV/JSON files with request statistics (throughput, latency, failures)
- Prometheus metrics: Verification that traffic appears in mub_request_processing_latency_milliseconds, mub_response_size, etc.
- Configuration: Workload parameters (users, spawn rate, duration) for different experiment scenarios

## 📋 Next Actions (2min)
- [ ] Create Python virtual environment (`python3 -m venv venv` or `python3 -m venv .venv`)
- [ ] Activate venv and install Locust (`pip install locust`)
- [ ] Create initial `locustfile.py` with stochastic pattern (GET to s0)
- [ ] Test headless execution: `locust -f locustfile.py --headless -u 10 -r 2 -t 1m --host http://localhost:9090`
- [ ] Verify traffic appears in Prometheus metrics
- [ ] Add trace-driven pattern (POST with JSON trace) to locustfile.py
- [ ] Document common workload parameter combinations for different topologies
- [ ] Test metric export (CSV/JSON) for later analysis

**Start Coding In**: ~30min (after brief completion)

---
**Total Planning Time**: ~30min | **Owner**: Researcher | **Date**: 2025-01-XX

<!-- Living Document - Update as you code -->

## 🔄 Implementation Tracking

**CRITICAL**: Follow the todo-list systematically. Mark items as complete, document blockers, update progress.

### Progress
- [x] Created Python virtual environment (using existing venv)
- [x] Installed Locust (v2.42.2) in venv
- [x] Created requirements.txt with Locust dependency
- [x] Created locustfile.py with stochastic pattern (GET to s0)
- [x] Added trace-driven pattern (POST with JSON trace) to locustfile.py
- [x] Created README.md with usage instructions and parameter guidelines
- [x] Validated locustfile.py syntax
- [x] Tested headless execution - **SUCCESS!** ✅
  - **Context**: Testing with standalone Python mock gateway (`gateway-tunnel-standalone-python.sh`)
  - GET requests: 198 requests, 0 failures (0.00%), 3.35 req/s, 51ms avg response time
  - Confirmed: Locust working, SSH tunnel working, mock gateway receiving requests
  - POST requests: 88 requests, 88 failures (100.00%) with 501 status (expected - mock gateway doesn't implement POST)
  - **Result**: Locust setup verified and ready for real muBench deployment
- [ ] Verify traffic appears in Prometheus metrics (requires deployed muBench app)

### Blockers
- None currently. 
- **Current Setup**: Using standalone Python mock gateway for testing (not real deployment)
- **For Real Benchmarking**: Will need:
  1. SSH tunnel running (`./scripts/gateway-tunnel-local.sh`)
  2. Real muBench application deployed and accessible via gateway
  3. Real deployment will support both GET (stochastic) and POST (trace-driven) benchmarks

**See**: [.sdd/IMPLEMENTATION_GUIDE.md](mdc:.sdd/IMPLEMENTATION_GUIDE.md) for detailed execution rules.

## 📝 Implementation Notes

### Gateway Access Details
- **URL**: `http://localhost:9090` (via SSH tunnel from gateway-tunnel-local.sh)
- **Stochastic Pattern**: `GET http://localhost:9090/s0` triggers random service calls per workmodel.json
- **Trace-Driven Pattern**: `POST http://localhost:9090/s0` with JSON trace body defining exact call sequence
- **Service Endpoints**: s0 (typical ingress), s1, s2, etc. depending on topology

### Locust Command Examples
```bash
# Basic headless execution
locust -f locustfile.py --headless -u 50 -r 5 -t 10m --host http://localhost:9090

# With metric export
locust -f locustfile.py --headless -u 50 -r 5 -t 10m --host http://localhost:9090 --csv=results

# Parameters:
# -u: Number of concurrent users
# -r: Spawn rate (users per second)
# -t: Test duration (e.g., 10m for 10 minutes, 2m for 2 minutes)
# --host: Base URL for requests
```

### Workload Parameter Guidelines (Preliminary)
- **Light Load**: u=10, r=2 (10 users, 2 per second spawn rate)
- **Medium Load**: u=50, r=5 (50 users, 5 per second spawn rate)
- **Heavy Load**: u=100, r=10 (100 users, 10 per second spawn rate)
- **Duration**: 2min warm-up + 8min measurement = 10m total (per Phase 3 requirements)

### Integration Points
- **SSH Tunnel**: Ensure `gateway-tunnel-local.sh` is running before Locust execution
- **Prometheus**: Verify metrics appear in Prometheus dashboard/query interface
- **Experiment Runner**: Future integration will control Locust execution for automated benchmarking

### Trace-Driven Benchmark Format
Example trace JSON structure (from Docs/Manual.md):
```json
{
   "s0__47072":[{
      "s24__71648":[{}],
      "s28__64944":[{
         "s6__5728":[{}],
         "s20__61959":[{}]
      }]
   }]
}
```

### Metric Collection
- **Locust Metrics**: Throughput (RPS), response times (min/avg/max), failure count
- **Prometheus Metrics**: mub_request_processing_latency_milliseconds, mub_response_size, etc.
- **Export Format**: CSV for analysis, JSON for programmatic processing

