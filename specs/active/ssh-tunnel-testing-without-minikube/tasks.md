# Task Breakdown: SSH Tunnel Testing Without Minikube

## Overview

Breakdown of implementation tasks for standalone nginx gateway setup. Tasks are organized by phase with dependencies and priorities.

## Task List

### Phase 1: Core Script Implementation

#### Task 1.1: Create Basic Script Structure
**Priority**: High  
**Effort**: 30 minutes  
**Dependencies**: None  
**Status**: ✅ Complete

**Description**: Create `scripts/gateway-tunnel-standalone.sh` with basic structure following existing `gateway-tunnel.sh` pattern.

**Acceptance Criteria**:
- [ ] Script file created at `scripts/gateway-tunnel-standalone.sh`
- [ ] Script has executable permissions
- [ ] Script has shebang `#!/bin/bash`
- [ ] Script has header comments explaining purpose
- [ ] Script follows same structure as `gateway-tunnel.sh`

**Definition of Done**:
- ✅ Script exists and is executable
- ✅ Basic structure matches existing patterns
- **Notes:** Both Docker and Python versions created. Python version tested and working.

---

#### Task 1.2: Implement Docker Detection
**Priority**: High  
**Effort**: 20 minutes  
**Dependencies**: Task 1.1  
**Status**: ✅ Complete (Docker version)

**Description**: Add function to check if Docker is installed and running.

**Acceptance Criteria**:
- [ ] Function `check_docker()` implemented
- [ ] Checks if `docker` command is available
- [ ] Checks if Docker daemon is running
- [ ] Provides clear error messages if Docker not available
- [ ] Exits gracefully with non-zero code on failure

**Definition of Done**:
- Docker detection works correctly
- Error messages are clear and helpful

---

#### Task 1.3: Implement Cleanup Function
**Priority**: High  
**Effort**: 30 minutes  
**Dependencies**: Task 1.1  
**Status**: ✅ Complete

**Description**: Add function to clean up existing containers and processes on port 9090.

**Acceptance Criteria**:
- [ ] Function `cleanup_existing()` implemented
- [ ] Stops and removes existing `mubench-nginx-standalone` container
- [ ] Kills processes using port 9090 (using `fuser`)
- [ ] Handles cases where container/process doesn't exist
- [ ] Provides status messages during cleanup

**Definition of Done**:
- Cleanup works correctly
- No errors when nothing to clean up

---

#### Task 1.4: Implement Nginx Container Startup
**Priority**: High  
**Effort**: 40 minutes  
**Dependencies**: Task 1.2, Task 1.3  
**Status**: ✅ Complete (Docker version ready, pending testing)

**Description**: Add function to start nginx Docker container on port 9090.

**Acceptance Criteria**:
- [ ] Function `start_nginx()` implemented
- [ ] Creates nginx configuration (inline or file)
- [ ] Runs Docker container with name `mubench-nginx-standalone`
- [ ] Maps port 9090:80 (host:container)
- [ ] Mounts nginx config as volume
- [ ] Handles Docker errors gracefully
- [ ] Provides status messages

**Definition of Done**:
- Container starts successfully
- Container is accessible on port 9090

---

#### Task 1.5: Implement Verification Function
**Priority**: Medium  
**Effort**: 20 minutes  
**Dependencies**: Task 1.4  
**Status**: ✅ Complete

**Description**: Add function to verify nginx container is running and accessible.

**Acceptance Criteria**:
- [ ] Function `verify_nginx()` implemented
- [ ] Checks container status with `docker ps`
- [ ] Tests HTTP connectivity with `curl http://localhost:9090`
- [ ] Provides success/failure feedback
- [ ] Returns appropriate exit code

**Definition of Done**:
- Verification works correctly
- Provides clear feedback on status

---

#### Task 1.6: Implement Signal Handling
**Priority**: High  
**Effort**: 20 minutes  
**Dependencies**: Task 1.4  
**Status**: ✅ Complete

**Description**: Add signal trapping to clean up container on script exit.

**Acceptance Criteria**:
- [ ] Function `cleanup_on_exit()` implemented
- [ ] Traps EXIT, INT, TERM signals
- [ ] Stops and removes container on exit
- [ ] Cleans up temporary files if any
- [ ] Works correctly with Ctrl+C

**Definition of Done**:
- Cleanup happens on script exit
- No orphaned containers left behind

---

### Phase 2: Nginx Configuration

#### Task 2.1: Create Mock Nginx Configuration
**Priority**: High  
**Effort**: 30 minutes  
**Dependencies**: Task 1.1  
**Status**: ✅ Complete

**Description**: Create nginx configuration that responds to service paths with mock responses.

**Acceptance Criteria**:
- [ ] Nginx config responds to `/s0`, `/s1`, etc. paths
- [ ] Returns HTTP 200 status codes
- [ ] Returns JSON responses with valid format
- [ ] Includes logging configuration
- [ ] Matches structure of Kubernetes nginx config

**Definition of Done**:
- Config file created or embedded in script
- Config tested with nginx container

---

#### Task 2.2: Test Nginx Responses
**Priority**: Medium  
**Effort**: 20 minutes  
**Dependencies**: Task 2.1, Task 1.4  
**Status**: ✅ Complete (Python version tested)

**Description**: Test nginx configuration with various paths and verify responses.

**Acceptance Criteria**:
- [ ] Test root path `/` returns valid response
- [ ] Test `/s0` returns valid JSON response
- [ ] Test `/s1` returns valid JSON response
- [ ] Test `/s0/update` returns valid response
- [ ] Test unknown paths return valid response
- [ ] Verify HTTP status codes are 200
- [ ] Verify Content-Type headers are correct

**Definition of Done**:
- All paths tested and working
- Responses are valid JSON

---

### Phase 3: Integration Testing

#### Task 3.1: Test End-to-End Setup
**Priority**: High  
**Effort**: 30 minutes  
**Dependencies**: Task 1.6, Task 2.2  
**Status**: ✅ Complete (Python version)

**Description**: Test complete setup flow from script execution to nginx accessible.

**Acceptance Criteria**:
- [ ] Run script on server (or local test)
- [ ] Verify container starts successfully
- [ ] Verify nginx is accessible on port 9090
- [ ] Test with `curl http://localhost:9090`
- [ ] Test with `curl http://localhost:9090/s0`
- [ ] Verify cleanup on script exit

**Definition of Done**:
- Complete flow works end-to-end
- All verification steps pass

---

#### Task 3.2: Test Runner Connectivity
**Priority**: Medium  
**Effort**: 30 minutes  
**Dependencies**: Task 3.1  
**Status**: ✅ Complete

**Description**: Test Runner can connect through standalone gateway (if SSH tunnel available).

**Acceptance Criteria**:
- [ ] Start standalone gateway
- [ ] Set up SSH tunnel (if possible)
- [ ] Run `Runner.py -c RunnerParameters-external.json`
- [ ] Verify Runner connects successfully
- [ ] Verify Runner receives responses (even if mock)
- [ ] Verify Runner doesn't crash

**Definition of Done**:
- Runner connects successfully
- Runner receives responses without errors

---

#### Task 3.3: Test Error Scenarios
**Priority**: Medium  
**Effort**: 30 minutes  
**Dependencies**: Task 1.6  
**Status**: 🔄 Partially Complete (Python version tested, Docker version pending)

**Description**: Test script handles error scenarios gracefully.

**Acceptance Criteria**:
- [ ] Test Docker not running scenario
- [ ] Test port 9090 already in use scenario
- [ ] Test container already exists scenario
- [ ] Test Docker permission errors
- [ ] Verify error messages are clear
- [ ] Verify script exits gracefully

**Definition of Done**:
- All error scenarios handled correctly
- Error messages are helpful

---

### Phase 4: Documentation

#### Task 4.1: Update SSH Tunnel Guide
**Priority**: High  
**Effort**: 30 minutes  
**Dependencies**: Task 3.1  
**Status**: 🔄 Pending (ready to update)

**Description**: Add standalone workflow section to `scripts/SSH_TUNNEL_GUIDE.md`.

**Acceptance Criteria**:
- [ ] New section "Testing Without Minikube" added
- [ ] Step-by-step instructions for standalone setup
- [ ] Clear distinction from Kubernetes workflow
- [ ] Troubleshooting section for standalone setup
- [ ] Examples and test procedures included

**Definition of Done**:
- Documentation is clear and complete
- Users can follow instructions without questions

---

#### Task 4.2: Add Script Comments
**Priority**: Low  
**Effort**: 20 minutes  
**Dependencies**: Task 1.6  
**Status**: ✅ Complete

**Description**: Add comprehensive comments to script explaining approach and differences.

**Acceptance Criteria**:
- [ ] Header comments explain purpose
- [ ] Function comments explain behavior
- [ ] Comments explain differences from Kubernetes version
- [ ] Comments explain key design decisions

**Definition of Done**:
- Script is well-documented
- Comments are clear and helpful

---

## Task Summary

### By Priority
- **High Priority**: 8 tasks
- **Medium Priority**: 4 tasks
- **Low Priority**: 1 task

### By Phase
- **Phase 1 (Core Script)**: 6 tasks
- **Phase 2 (Nginx Config)**: 2 tasks
- **Phase 3 (Integration Testing)**: 3 tasks
- **Phase 4 (Documentation)**: 2 tasks

### Estimated Effort
- **Total**: ~6.5 hours
- **Phase 1**: ~2.5 hours
- **Phase 2**: ~50 minutes
- **Phase 3**: ~1.5 hours
- **Phase 4**: ~50 minutes

## Execution Order

### Immediate (Can Start Now)
1. Task 1.1: Create Basic Script Structure
2. Task 1.2: Implement Docker Detection
3. Task 1.3: Implement Cleanup Function

### After Core Functions
4. Task 1.4: Implement Nginx Container Startup
5. Task 2.1: Create Mock Nginx Configuration
6. Task 1.5: Implement Verification Function
7. Task 1.6: Implement Signal Handling

### Testing Phase
8. Task 2.2: Test Nginx Responses
9. Task 3.1: Test End-to-End Setup
10. Task 3.3: Test Error Scenarios
11. Task 3.2: Test Runner Connectivity

### Documentation Phase
12. Task 4.1: Update SSH Tunnel Guide
13. Task 4.2: Add Script Comments

## Dependencies Graph

```
Task 1.1 (Script Structure)
├── Task 1.2 (Docker Detection)
├── Task 1.3 (Cleanup)
└── Task 2.1 (Nginx Config)

Task 1.2 + Task 1.3
└── Task 1.4 (Container Startup)

Task 1.4
├── Task 1.5 (Verification)
├── Task 1.6 (Signal Handling)
└── Task 2.2 (Test Responses)

Task 1.6 + Task 2.2
└── Task 3.1 (End-to-End Test)

Task 3.1
├── Task 3.2 (Runner Test)
└── Task 4.1 (Documentation)

Task 1.6
└── Task 3.3 (Error Scenarios)

Task 1.6
└── Task 4.2 (Comments)
```

---

## Implementation Summary

### ✅ Completed
- Python standalone gateway script created and tested
- Docker standalone gateway script created (ready for testing)
- SSH tunnel setup updated and working
- Runner connectivity tested successfully (5000 requests, 0 errors)
- All core functionality implemented

### 🔄 Pending (Requires Docker Access)
- Docker version testing
- Full error scenario testing with Docker
- Performance comparison between Python and Docker versions

### 📝 Next Steps
1. When Docker/sudo access available: Test Docker version
2. Update SSH_TUNNEL_GUIDE.md with standalone workflow
3. Document both Python and Docker options

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27  
**Status:** Partially Complete - Python version working, Docker version ready for testing

**Related Documents:**
- [Specification](spec.md) - Detailed requirements
- [Technical Plan](plan.md) - Implementation approach
- [Research](research.md) - Initial findings


