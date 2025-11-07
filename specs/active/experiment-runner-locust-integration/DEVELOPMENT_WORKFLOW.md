# Development Workflow: Multi-Repository Experiment Setup

**Inspired by**: [AndroidTimeMachine/open_source_android_apps](https://github.com/AndroidTimeMachine/open_source_android_apps) - A tool that coordinates multiple data sources (GitHub, Google Play) to build a connected dataset.

## Overview

This document describes how to continue working on the full experiment flow when you have **two separate repositories** that need to work together:

1. **experiment-runner** (S2-group/experiment-runner) - Orchestration framework
2. **muBench** (your repository) - Benchmarking system

Similar to how AndroidTimeMachine coordinates GitHub and Google Play data sources, we coordinate Experiment Runner and muBench to orchestrate benchmarking experiments.

## Repository Structure

```
~/Documents/Research Project/
├── experiment-runner/                    # Repository 1: Orchestration framework
│   ├── examples/
│   │   └── mubench-benchmarking/
│   │       ├── RunnerConfig.py          # Main integration code
│   │       └── README.md
│   └── ... (experiment-runner framework)
│
└── muBench/                              # Repository 2: Benchmarking system
    ├── Benchmarks/Locust/                # Locust workload generator
    ├── Deployers/K8sDeployer/            # Kubernetes deployment
    ├── scripts/                          # SSH tunnel scripts
    ├── specs/active/
    │   └── experiment-runner-locust-integration/
    │       ├── feature-brief.md          # SDD documentation
    │       ├── CURRENT_STATUS.md
    │       ├── HANDOFF.md
    │       ├── GIT_STRATEGY.md
    │       └── DEVELOPMENT_WORKFLOW.md   # This file
    └── ... (muBench system)
```

## Key Principles (Inspired by AndroidTimeMachine)

### 1. **Main Orchestrator Pattern**
- **experiment-runner** is the main orchestrator (like `gh_android_apps.py`)
- **muBench** provides the data/benchmarking capabilities (like GitHub/Google Play)
- RunnerConfig.py coordinates between them using relative paths

### 2. **Independent Repositories**
- Each repository maintains its own version control
- Changes can be made independently
- Coordination happens through:
  - Relative paths in RunnerConfig.py
  - Environment variables (if needed)
  - Shared configuration files (if needed)

### 3. **Structured Workflow**
- Clear subcommands/workflows for each phase
- Documented dependencies between steps
- Results stored in structured format

## Development Workflow

### Phase 1: Initial Setup (One-Time)

**1. Clone both repositories:**
```bash
cd ~/Documents/Research\ Project/
git clone <experiment-runner-repo> experiment-runner
git clone <muBench-repo> muBench
```

**2. Set up branches:**
```bash
# Experiment Runner
cd experiment-runner
git checkout -b muBench-Irena
git push -u origin muBench-Irena

# muBench
cd ../muBench
git checkout -b pr-two-machine-testing
git push -u origin pr-two-machine-testing
```

**3. Verify path relationship:**
```bash
# From experiment-runner/examples/mubench-benchmarking/
# Should resolve to: ~/Documents/Research Project/muBench/
python3 -c "from pathlib import Path; from os.path import dirname, realpath; ROOT_DIR = Path(dirname(realpath('RunnerConfig.py'))); MUBENCH_DIR = ROOT_DIR.parent.parent.parent / 'muBench'; print(f'muBench path: {MUBENCH_DIR}'); print(f'Exists: {MUBENCH_DIR.exists()}')"
```

### Phase 2: Development Cycle

#### Step 1: Make Changes in muBench

**Workflow:**
1. Make changes in muBench repository
2. Test changes locally
3. Commit to `pr-two-machine-testing` branch
4. Push to GitHub

**Example:**
```bash
cd ~/Documents/Research\ Project/muBench

# Make changes (e.g., update Locust config)
vim Benchmarks/Locust/locustfile.py

# Test locally
./scripts/gateway-tunnel-standalone-python.sh
# In another terminal:
locust -f Benchmarks/Locust/locustfile.py --headless -u 10 -r 2 -t 1m --host http://localhost:9090

# Commit and push
git add Benchmarks/Locust/locustfile.py
git commit -m "feat(locust): update workload configuration"
git push origin pr-two-machine-testing
```

#### Step 2: Update Experiment Runner Integration

**Workflow:**
1. Update RunnerConfig.py to use new muBench features
2. Test integration locally
3. Commit to `muBench-Irena` branch
4. Push to GitHub

**Example:**
```bash
cd ~/Documents/Research\ Project/experiment-runner

# Update RunnerConfig.py to use new Locust features
vim examples/mubench-benchmarking/RunnerConfig.py

# Test integration
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py --dry-run

# Commit and push
git add examples/mubench-benchmarking/RunnerConfig.py
git commit -m "feat(mubench): integrate updated Locust configuration"
git push origin muBench-Irena
```

#### Step 3: Test Full Flow

**Workflow:**
1. Ensure both repositories are up to date
2. Test end-to-end workflow
3. Verify results
4. Update SDD documentation

**Example:**
```bash
# Pull latest changes
cd ~/Documents/Research\ Project/experiment-runner
git pull origin muBench-Irena

cd ../muBench
git pull origin pr-two-machine-testing

# Test full flow
cd ~/Documents/Research\ Project/experiment-runner
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py

# Verify results
ls -la examples/mubench-benchmarking/experiments/

# Update SDD docs
cd ../muBench
vim specs/active/experiment-runner-locust-integration/CURRENT_STATUS.md
git add specs/active/experiment-runner-locust-integration/
git commit -m "docs(sdd): update status after full flow test"
git push origin pr-two-machine-testing
```

### Phase 3: Continuous Development

#### Daily Workflow

**Morning:**
```bash
# Pull latest changes from both repos
cd ~/Documents/Research\ Project/experiment-runner
git pull origin muBench-Irena

cd ../muBench
git pull origin pr-two-machine-testing
```

**During Development:**
- Make changes in appropriate repository
- Test locally
- Commit frequently with descriptive messages
- Push to respective branches

**End of Day:**
```bash
# Push all changes
cd ~/Documents/Research\ Project/experiment-runner
git push origin muBench-Irena

cd ../muBench
git push origin pr-two-machine-testing
```

#### Coordinating Changes

**When muBench changes affect Experiment Runner:**

1. **Update muBench first:**
   ```bash
   cd ~/Documents/Research\ Project/muBench
   # Make changes
   git commit -m "feat: add new feature X"
   git push origin pr-two-machine-testing
   ```

2. **Update Experiment Runner to use new feature:**
   ```bash
   cd ~/Documents/Research\ Project/experiment-runner
   # Update RunnerConfig.py
   git commit -m "feat(mubench): integrate new feature X"
   git push origin muBench-Irena
   ```

3. **Update SDD documentation:**
   ```bash
   cd ~/Documents/Research\ Project/muBench
   # Update feature-brief.md or CURRENT_STATUS.md
   git commit -m "docs(sdd): document integration of feature X"
   git push origin pr-two-machine-testing
   ```

**When Experiment Runner changes affect muBench:**

1. **Update Experiment Runner:**
   ```bash
   cd ~/Documents/Research\ Project/experiment-runner
   # Make changes
   git commit -m "feat: add new orchestration feature Y"
   git push origin muBench-Irena
   ```

2. **Update muBench to work with new feature:**
   ```bash
   cd ~/Documents/Research\ Project/muBench
   # Update scripts/configs to work with new feature
   git commit -m "feat: adapt to experiment-runner feature Y"
   git push origin pr-two-machine-testing
   ```

3. **Update SDD documentation:**
   ```bash
   cd ~/Documents/Research\ Project/muBench
   # Update feature-brief.md
   git commit -m "docs(sdd): document experiment-runner feature Y integration"
   git push origin pr-two-machine-testing
   ```

## Testing Strategy

### Unit Testing (Per Repository)

**muBench:**
```bash
cd ~/Documents/Research\ Project/muBench
# Test Locust
locust -f Benchmarks/Locust/locustfile.py --headless -u 10 -r 2 -t 1m --host http://localhost:9090

# Test SSH tunnel
./scripts/gateway-tunnel-local.sh

# Test deployment (if minikube available)
python Deployers/K8sDeployer/RunK8sDeployer.py -c Configs/K8sParameters.json
```

**Experiment Runner:**
```bash
cd ~/Documents/Research\ Project/experiment-runner
# Test RunnerConfig.py syntax
python3 -c "from examples.mubench_benchmarking.RunnerConfig import RunnerConfig; print('✓ Config loads successfully')"

# Test with dry-run (if supported)
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py --dry-run
```

### Integration Testing (Full Flow)

```bash
# 1. Start standalone gateway
cd ~/Documents/Research\ Project/muBench
./scripts/gateway-tunnel-standalone-python.sh &
GATEWAY_PID=$!

# 2. Run Experiment Runner
cd ~/Documents/Research\ Project/experiment-runner
python experiment-runner/ examples/mubench-benchmarking/RunnerConfig.py

# 3. Verify results
ls -la examples/mubench-benchmarking/experiments/
cat examples/mubench-benchmarking/experiments/run_table.csv

# 4. Cleanup
kill $GATEWAY_PID
```

## Version Coordination

### Branch Naming Convention

**Experiment Runner:**
- Branch: `muBench-Irena` (or `mubench-integration`)
- Purpose: muBench-specific integration

**muBench:**
- Branch: `pr-two-machine-testing` (or experiment-specific name)
- Purpose: Experiment development with SDD documentation

### Tagging Strategy

**When experiment is complete:**
```bash
# Tag Experiment Runner
cd ~/Documents/Research\ Project/experiment-runner
git tag -a v1.0.0-mubench-integration -m "muBench integration complete"
git push origin v1.0.0-mubench-integration

# Tag muBench
cd ../muBench
git tag -a v1.0.0-experiment-runner-integration -m "Experiment Runner integration complete"
git push origin v1.0.0-experiment-runner-integration
```

## Pull Request Strategy

### Experiment Runner PR

**When ready:**
1. Ensure all tests pass
2. Update README.md in `examples/mubench-benchmarking/`
3. Create PR from `muBench-Irena` to `master`
4. Reference muBench branch/PR in description

**PR Description Template:**
```markdown
## Overview
Adds muBench Phase 3 benchmarking integration to Experiment Runner.

## Changes
- ✅ RunnerConfig.py with 540-run experiment design
- ✅ SSH tunnel integration
- ✅ Locust execution integration
- ✅ Locust metric parsing
- ✅ Documentation

## Related
- muBench PR: #XXX (pr-two-machine-testing branch)
- SDD Documentation: muBench/specs/active/experiment-runner-locust-integration/

## Testing
- [x] Basic execution
- [x] Locust integration
- [x] End-to-end workflow
- [x] Metric parsing
```

### muBench PR

**When ready:**
1. Ensure all tests pass
2. Update SDD documentation
3. Create PR from `pr-two-machine-testing` to `master`
4. Reference Experiment Runner PR in description

**PR Description Template:**
```markdown
## Overview
Adds Experiment Runner integration for Phase 3 benchmarking experiments.

## Changes
- ✅ SDD documentation (feature-brief.md, CURRENT_STATUS.md, etc.)
- ✅ Integration with Experiment Runner (experiment-runner/muBench-Irena branch)
- ✅ Development workflow documentation

## Related
- Experiment Runner PR: #XXX (muBench-Irena branch)
- SDD Documentation: specs/active/experiment-runner-locust-integration/

## Testing
- [x] Locust workload generation
- [x] SSH tunnel setup
- [x] Experiment Runner integration
- [x] End-to-end workflow
```

## Troubleshooting

### Path Issues

**Problem:** RunnerConfig.py can't find muBench directory

**Solution:**
```bash
# Verify path relationship
cd ~/Documents/Research\ Project/experiment-runner/examples/mubench-benchmarking
python3 -c "
from pathlib import Path
from os.path import dirname, realpath
ROOT_DIR = Path(dirname(realpath('RunnerConfig.py')))
MUBENCH_DIR = ROOT_DIR.parent.parent.parent / 'muBench'
print(f'Expected: ~/Documents/Research Project/muBench')
print(f'Resolved: {MUBENCH_DIR}')
print(f'Exists: {MUBENCH_DIR.exists()}')
"
```

### Version Mismatch

**Problem:** Experiment Runner expects different muBench structure

**Solution:**
1. Check RunnerConfig.py path references
2. Update paths if muBench structure changed
3. Test with standalone gateway first
4. Update SDD documentation

### Git Conflicts

**Problem:** Conflicts when pulling changes

**Solution:**
```bash
# Pull with rebase to maintain linear history
git pull --rebase origin <branch-name>

# If conflicts, resolve and continue
git add <resolved-files>
git rebase --continue
```

## Best Practices

### 1. **Keep Repositories Synchronized**
- Pull latest changes before starting work
- Push changes frequently
- Coordinate major changes

### 2. **Document Changes**
- Update SDD documentation in muBench
- Update README.md in Experiment Runner
- Cross-reference changes in commit messages

### 3. **Test Incrementally**
- Test changes in each repository independently
- Test integration after changes
- Verify full flow before committing

### 4. **Maintain Path Relationships**
- Use relative paths in RunnerConfig.py
- Document path assumptions
- Verify paths work across different environments

### 5. **Version Control**
- Use descriptive branch names
- Commit frequently with clear messages
- Tag releases when experiments complete

## References

- **AndroidTimeMachine Pattern**: [open_source_android_apps](https://github.com/AndroidTimeMachine/open_source_android_apps) - Coordinates multiple data sources (GitHub, Google Play)
- **Experiment Runner**: [S2-group/experiment-runner](https://github.com/S2-group/experiment-runner) - Orchestration framework
- **SDD Documentation**: `specs/active/experiment-runner-locust-integration/feature-brief.md`
- **Git Strategy**: `specs/active/experiment-runner-locust-integration/GIT_STRATEGY.md`

## Summary

**Key Takeaways:**
1. **Two independent repositories** - Each maintains its own version control
2. **Coordinated through paths** - RunnerConfig.py uses relative paths to muBench
3. **SDD documentation in muBench** - All documentation lives in muBench repository
4. **Incremental development** - Make changes, test, commit, push
5. **Full flow testing** - Test integration regularly
6. **PR coordination** - Reference related PRs when creating pull requests

**Workflow Pattern:**
```
Make Changes → Test Locally → Commit → Push → Test Integration → Update Docs → Repeat
```

This pattern allows you to continue development on the full experiment flow while maintaining clear separation between the two repositories.

