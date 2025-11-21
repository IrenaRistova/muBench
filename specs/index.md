# SDD Features Index

## Navigation
- [📋 Project Overview](00-overview.md)
- [📖 Guidelines](../.sdd/guidelines.md)
- [⚙️ Configuration](../.sdd/config.json)

## Feature Status Dashboard

### Active Features (In Development)
- **experiment-runner-locust-integration** - Integrate Experiment Runner with Locust to orchestrate muBench benchmarking ✅ **TESTED**
  - Status: Basic integration tested and verified
  - Location: `specs/active/experiment-runner-locust-integration/`
  - Implementation: `experiment-runner/examples/mubench-benchmarking/`
  - Progress: See [feature-brief.md](active/experiment-runner-locust-integration/feature-brief.md)
  - Test Results: See [TEST_RESULTS.md](active/experiment-runner-locust-integration/TEST_RESULTS.md)
  - Notes: RunnerConfig.py created with RunTableModel (540 runs), SSH tunnel and Locust integration complete and tested. Deployment and Prometheus integration pending (require minikube/Prometheus).

- **locust-workload-setup** - Locust workload generator setup for Phase 3 benchmarking ✅ **COMPLETE**
  - Status: Complete and tested
  - Location: `specs/active/locust-workload-setup/`
  - Implementation: `Benchmarks/Locust/`
  - Progress: See [feature-brief.md](active/locust-workload-setup/feature-brief.md)
  - Notes: Locust v2.42.2 installed, locustfile.py created with stochastic and trace-driven patterns, tested with mock gateway. Ready for real muBench deployment.

- **ssh-tunnel-testing-without-minikube** - Standalone gateway setup for SSH tunnel testing without minikube
  - Status: Partially Complete (Python version ✅, Docker version 🔄 pending, Documentation 📝 pending)
  - Location: `specs/active/ssh-tunnel-testing-without-minikube/`
  - Progress: See [progress.md](active/ssh-tunnel-testing-without-minikube/progress.md)
  - Notes: Python standalone gateway working and tested. Docker version ready but needs Docker/sudo access. Documentation update pending.

### Completed Features
Currently no fully completed features.

### Backlog Features
Currently no backlog features.

## Quick Actions
- 🆕 [Create New Feature](active/)
- 📊 [View All Features](.)
- 📝 [Update Guidelines](../.sdd/guidelines.md)
- ⚙️ [Modify Configuration](../.sdd/config.json)

## Statistics
- **Total Features**: 3
- **Active**: 3 (2 complete/tested, 1 partially complete)
- **Completed**: 0 (moved to active with complete status)
- **Backlog**: 0

## Recent Activity
- **2025-11-07**: Experiment Runner + Locust integration tested ✅ - Basic integration verified and working, test results documented
- **2025-01-XX**: Experiment Runner + Locust integration started 🔄 - RunnerConfig.py created, basic integration complete
- **2025-01-XX**: Locust workload generator integrated ✅ - Installed, tested, and ready for Phase 3 benchmarking
- **2025-01-27**: SSH tunnel testing setup - Python version working ✅, Docker version ready 🔄, Documentation pending 📝

---
Last updated: 2025-11-07


