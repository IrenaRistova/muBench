# Next Steps for Testing

## Summary of What We've Done

✅ **Implementation Complete**:
- All functions implemented in `RunnerConfig.py`
- Workmodel mapping tested (18/18 combinations verified)
- K8sParameters generation tested
- Gateway port-forward management added (restarts per run)

✅ **Documentation Complete**:
- `DEPLOYMENT_WORKFLOW.md` - Complete workflow breakdown
- `DEPLOYMENT_IMPLEMENTATION.md` - Updated with workflow phases
- `TESTING_GUIDE.md` - Step-by-step testing instructions

## What to Test Next

### Step 1: Verify Server Setup

**On Server (gl3)**:
```bash
# Check if setup-infrastructure.sh has been run
kubectl get nodes
kubectl get pods -n monitoring
kubectl get svc -n monitoring prometheus-nodeport

# If not set up, run:
cd /root/muBench
./scripts/setup-infrastructure.sh
```

### Step 2: Start Per-Experiment Setup

**On Server (gl3)** - Start Prometheus port-forward:
```bash
# Start Prometheus port-forward (stays running for all runs)
cd /root/muBench
./scripts/start-prometheus-port-forward.sh
# OR manually:
# kubectl -n monitoring port-forward svc/prometheus-nodeport 30000:9090 &
```

**Note**: Gateway port-forward cannot be started here because the gateway service doesn't exist until after deployment. Experiment Runner will start it after each deployment.

**On Host** - Start SSH tunnels:
```bash
cd ~/Documents/Research\ Project/muBench
./scripts/tunnels-local.sh
```

**Verify**:
```bash
# On host
curl http://localhost:30000/api/v1/status/config  # Should work
```

### Step 3: Test Single Run End-to-End

**Modify RunnerConfig.py for testing**:
- Set `repetitions=1` (already set)
- Set `LOCUST_DURATION="10s"` (already set)
- Set `time_between_runs_in_ms=5000` (already set)

**Run experiment**:
```bash
cd ~/Documents/Research\ Project/experiment-runner
source venv/bin/activate
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py
```

**Watch for**:
1. ✅ Workmodel mapping works
2. ✅ Namespace creation works (may need SSH for kubectl)
3. ✅ K8sDeployer execution (may need SSH)
4. ✅ Pod readiness wait
5. ✅ Gateway port-forward started
6. ✅ Gateway verification
7. ✅ Locust execution
8. ✅ Prometheus queries
9. ✅ Metric parsing

### Step 4: Fix Any Issues

**Common issues to watch for**:

1. **kubectl context not set**:
   - Solution: Use SSH for kubectl commands
   - Or: Set kubectl context to point to server

2. **K8sDeployer must run on server**:
   - Solution: Execute via SSH: `ssh gl3 "cd /root/muBench && python3 Deployers/K8sDeployer/RunK8sDeployer.py -c <config>"`

3. **Gateway port-forward fails**:
   - Check: Service exists in namespace
   - Check: SSH access to gl3 works
   - Check: Port 9090 not in use on server

4. **Prometheus queries return None**:
   - Check: Prometheus port-forward running
   - Check: SSH tunnel running
   - Check: PodMonitor deployed
   - Check: Pods have prometheus.io/scrape annotation

### Step 5: Test Multiple Runs

Once single run works:
- Increase `repetitions=2` or `3`
- Test namespace isolation
- Test cleanup between runs
- Verify gateway port-forward updates correctly

### Step 6: Scale Up

Once multiple runs work:
- Increase `LOCUST_DURATION` to `"10m"`
- Increase `repetitions` to `30`
- Test with all 18 topology+size combinations
- Run full 540-run experiment

## Key Points to Remember

1. **One-time setup**: `setup-infrastructure.sh` runs once (minikube + Prometheus, no workmodel deployment)
2. **Per-experiment setup**: Prometheus port-forward + SSH tunnels (run once per experiment)
3. **Per-run**: Gateway port-forward must be restarted (namespace changes)
4. **K8sDeployer**: Must run on server (where minikube is)
5. **kubectl**: May need SSH if context not set on host

## Current Status

- ✅ Code implementation complete
- ✅ Basic functions tested (workmodel mapping, K8sParameters)
- ⏸️ Server-dependent functions need testing (namespace, deployment, Prometheus)
- 🔄 Ready to test with actual server setup


