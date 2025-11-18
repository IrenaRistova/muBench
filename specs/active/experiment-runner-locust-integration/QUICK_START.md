# Quick Start: Run Your First Test Experiment

**📖 For complete setup instructions, see [EXPERIMENT_RUN_GUIDE.md](EXPERIMENT_RUN_GUIDE.md)**

## Current Status ✅

- ✅ **FULLY WORKING**: All 18 test runs completed successfully
- ✅ Server: `setup-infrastructure.sh` completed (minikube + Prometheus)
- ✅ Server: Prometheus port-forward running
- ✅ Host: SSH tunnels running (both gateway and Prometheus)
- ✅ Prometheus accessible from host
- ✅ Full deployment integration working
- ✅ All metrics being collected (Locust + Prometheus)

## Quick Setup (Before Each Experiment)

**1. Clean up old experiments (from host):**
```bash
ssh gl3 "cd ~/muBench && ./scripts/cleanup-experiments.sh --all"
```

**2. Start Prometheus port-forward (on server):**
```bash
ssh gl3 "cd ~/muBench && ./scripts/start-prometheus-port-forward.sh"
```

**3. Start SSH tunnels (on host):**
```bash
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh
```

**4. Clean up old experiment directory (on host):**
```bash
rm -rf ~/Documents/Research\ Project/experiment-runner/examples/mubench-benchmarking/experiments/mubench_phase3_benchmarking
```

## Run the Experiment 🚀

```bash
cd ~/Documents/Research\ Project/experiment-runner
source venv/bin/activate
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
```

### What Will Happen

1. **Workmodel Mapping**: Maps topology+size to workmodel file
2. **Cleanup**: Deletes any existing deployments for same topology+size
3. **Namespace Creation**: Creates `mubench-{topology}-{size}-{replicate}` namespace
4. **K8sParameters Generation**: Creates config file for this run
5. **Deployment**: Executes K8sDeployer to deploy muBench application
6. **Pod Wait**: Waits for all pods to be ready
7. **Gateway Port-Forward**: Starts port-forward for gateway (service now exists!)
8. **Gateway Verification**: Tests gateway accessibility
9. **Locust Execution**: Runs workload (10s duration for testing)
10. **Prometheus Queries**: Collects CPU and memory metrics
11. **Metric Parsing**: Parses and stores results

### Watch For

- ✅ Namespace creation works
- ✅ K8sDeployer execution (may need SSH if kubectl context not set)
- ✅ Pods become ready
- ✅ Gateway port-forward starts successfully
- ✅ Gateway accessible
- ✅ Locust executes
- ✅ Prometheus queries work
- ✅ Results saved to `experiments/mubench_phase3_benchmarking/`

### If Something Fails

**K8sDeployer fails**: May need to run via SSH. Check the error message.

**Gateway port-forward fails**: Check that deployment succeeded and gateway service exists.

**Prometheus queries return None**: Check Prometheus port-forward is running on server.

### After Test Succeeds

Once one run works:
1. Test multiple runs (increase `repetitions` in RunnerConfig.py)
2. Test with longer Locust duration
3. Scale up to full experiment (540 runs)

