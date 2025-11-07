# Technical Plan: SSH Tunnel Testing Without Minikube

## Overview

This plan outlines the technical approach for creating a standalone nginx gateway setup that allows SSH tunnel testing without requiring minikube/Kubernetes. The solution will provide a Docker-based nginx container that mimics the Kubernetes gateway service, enabling developers to test SSH tunnels and Runner connectivity without full application deployment.

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Host Machine (Local)                      │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  gateway-tunnel-local.sh (existing, no changes)     │   │
│  │  SSH Tunnel: localhost:9090 → gl3:9090              │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                  │
│                           │ SSH Tunnel                      │
│                           │ (port 9090)                     │
└───────────────────────────┼─────────────────────────────────┘
                             │
                             │
┌───────────────────────────┼─────────────────────────────────┐
│                    Jump Host (glgate)                        │
│                    145.108.225.3:42224                      │
└───────────────────────────┼─────────────────────────────────┘
                             │
                             │
┌───────────────────────────┼─────────────────────────────────┐
│              Remote Server (gl3)                             │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  gateway-tunnel-standalone.sh (NEW)                   │   │
│  │  ┌───────────────────────────────────────────────┐  │   │
│  │  │  Docker Container: mubench-nginx-standalone    │  │   │
│  │  │  Port: 9090:80                                  │  │   │
│  │  │  ┌───────────────────────────────────────────┐ │  │   │
│  │  │  │  Nginx (port 80)                           │ │  │   │
│  │  │  │  Mock Config: responds to /s0, /s1, etc.  │ │  │   │
│  │  │  └───────────────────────────────────────────┘ │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  gateway-tunnel.sh (existing, coexists)             │   │
│  │  Uses: kubectl port-forward (requires Kubernetes)   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Component Design

#### Component 1: Standalone Gateway Script (`gateway-tunnel-standalone.sh`)
**Responsibilities:**
- Check for and clean up existing containers/processes on port 9090
- Start nginx Docker container on port 9090
- Verify container is running and accessible
- Handle cleanup on script exit (trap signals)
- Provide clear status messages and instructions

**Interfaces:**
- Input: None (script execution)
- Output: Nginx container running on port 9090
- Exit codes: 0 (success), 1 (error)

**Design Pattern:**
- Follows same pattern as `gateway-tunnel.sh` for consistency
- Uses Docker CLI for container management
- Implements cleanup and error handling similar to existing scripts

#### Component 2: Mock Nginx Configuration (`nginx-standalone.conf`)
**Responsibilities:**
- Respond to service paths (e.g., `/s0`, `/s1`) with mock HTTP responses
- Return valid HTTP 200 responses
- Provide JSON or text content for Runner compatibility
- Log requests for debugging

**Interfaces:**
- Input: HTTP GET requests to `/s0`, `/s1`, etc.
- Output: HTTP 200 responses with mock content

**Design Pattern:**
- Based on Kubernetes nginx config template structure
- Uses nginx `return` directive for mock responses
- Includes logging similar to Kubernetes version

#### Component 3: Documentation Updates (`SSH_TUNNEL_GUIDE.md`)
**Responsibilities:**
- Document standalone workflow
- Explain differences from Kubernetes workflow
- Provide troubleshooting guidance
- Include examples and test procedures

**Interfaces:**
- Input: User reading documentation
- Output: Clear instructions for testing

## Technology Stack

### Core Technologies

#### Docker
**Choice**: Docker container for nginx
**Justification:**
- No Kubernetes required
- Consistent with existing muBench Docker usage
- Easy to manage and clean up
- Standard nginx image from Docker Hub

**Implementation:**
- Use official `nginx` image (latest or specific version)
- Container name: `mubench-nginx-standalone`
- Port mapping: `9090:80` (host:container)

#### Nginx
**Choice**: Standard nginx web server
**Justification:**
- Matches Kubernetes gateway configuration
- Lightweight and fast
- Easy to configure for mock responses
- Standard HTTP server for testing

**Implementation:**
- Use official nginx Docker image
- Custom configuration file mounted as volume
- Listen on port 80 inside container

#### Bash Scripting
**Choice**: Bash shell script
**Justification:**
- Consistent with existing scripts (`gateway-tunnel.sh`, `monitoring-tunnel.sh`)
- Simple and maintainable
- Good for system automation
- Works on Linux servers

**Implementation:**
- Bash 4.0+ compatibility
- Use standard tools: `docker`, `ps`, `grep`, `fuser`, `curl`
- Follow existing script patterns

### Supporting Technologies

#### Standard Tools
- **docker**: Container management
- **ps/grep**: Process detection
- **fuser**: Port conflict detection
- **curl**: Connectivity testing

## Implementation Details

### Script Structure

#### File: `scripts/gateway-tunnel-standalone.sh`

**Structure:**
```bash
#!/bin/bash

# Header and documentation
# Variable definitions
# Function definitions:
#   - check_docker()
#   - cleanup_existing()
#   - start_nginx()
#   - verify_nginx()
#   - cleanup_on_exit()
# Main execution flow
# Signal handling (trap)
```

**Key Functions:**

1. **check_docker()**
   - Verify Docker daemon is running
   - Check Docker CLI is available
   - Provide helpful error messages if not available

2. **cleanup_existing()**
   - Stop and remove existing `mubench-nginx-standalone` container
   - Kill processes using port 9090
   - Clean up any orphaned containers

3. **start_nginx()**
   - Create nginx configuration file (if needed)
   - Run Docker container with proper options
   - Mount configuration file as volume
   - Map port 9090:80

4. **verify_nginx()**
   - Check container is running
   - Test HTTP connectivity with curl
   - Provide status feedback

5. **cleanup_on_exit()**
   - Trap EXIT, INT, TERM signals
   - Stop and remove container on exit
   - Clean up temporary files

**Error Handling:**
- Docker not running → Clear error message, exit 1
- Port conflict → Attempt cleanup, provide guidance
- Container start failure → Log error, cleanup, exit 1
- Permission errors → Clear message about Docker group

### Nginx Configuration

#### File: `scripts/nginx-standalone.conf` (or inline in script)

**Structure:**
```nginx
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log;

events {
    worker_connections 10240;
}

http {
    log_format main '[STANDALONE-GATEWAY] - $remote_addr - [$time_local] "$request_method $request_uri" $status';
    
    access_log /var/log/nginx/access.log main;
    
    server {
        listen 80;
        server_name _;
        
        # Root path - return default response
        location = / {
            return 200 '{"status": "ok", "message": "muBench Standalone Gateway"}';
            add_header Content-Type application/json;
        }
        
        # Service paths - mock responses for Runner
        location ~ ^/(s[0-9]+)$ {
            set $service $1;
            return 200 '{"service": "$service", "status": "ok", "message": "Mock response from standalone gateway"}';
            add_header Content-Type application/json;
        }
        
        # Service paths with update endpoint
        location ~ ^/(s[0-9]+)/update$ {
            set $service $1;
            return 200 '{"service": "$service", "status": "updated", "message": "Mock update response"}';
            add_header Content-Type application/json;
        }
        
        # Default catch-all
        location / {
            return 200 '{"status": "ok", "path": "$request_uri", "message": "Mock response"}';
            add_header Content-Type application/json;
        }
    }
}
```

**Key Features:**
- Responds to `/s0`, `/s1`, etc. with mock JSON responses
- Returns HTTP 200 status codes
- Includes logging for debugging
- Matches expected path patterns from Runner

**Alternative Approach:**
- Generate config file dynamically in script
- Or embed config inline using heredoc
- Or create config file in script directory

### Integration Points

#### With Existing Scripts

**gateway-tunnel-local.sh** (Host-side)
- **No changes needed**
- Works with standalone gateway on port 9090
- User chooses which server-side script to use

**gateway-tunnel.sh** (Server-side, Kubernetes)
- **Coexists** with standalone script
- User chooses based on environment
- Both use port 9090 (user must choose one)

**monitoring-tunnel.sh** (Server-side)
- **Independent** - no interaction
- Uses different ports (30000-30003)

#### With Documentation

**SSH_TUNNEL_GUIDE.md**
- Add new section: "Testing Without Minikube"
- Include standalone workflow steps
- Explain differences and limitations
- Add troubleshooting for standalone setup

## Security Considerations

### Container Security
- **No privileged mode**: Run nginx container without `--privileged`
- **Read-only config**: Mount nginx config as read-only
- **No host network**: Use port mapping instead of `--network host`
- **Standard user**: Nginx runs as nginx user inside container

### Network Security
- **Local access only**: Container listens on localhost (127.0.0.1)
- **No external exposure**: Port 9090 only accessible via SSH tunnel
- **No authentication**: Testing only, not for production

### Script Security
- **No sudo required**: Script should work with Docker group membership
- **Input validation**: Script doesn't accept user input (no injection risk)
- **Error handling**: Graceful failure, no information leakage

## Performance Considerations

### Container Startup
- **Target**: Container starts within 5 seconds
- **Approach**: Use standard nginx image (no custom build)
- **Optimization**: Pre-pull nginx image if needed

### Script Execution
- **Target**: Script completes setup within 10 seconds
- **Approach**: Minimal cleanup, efficient Docker commands
- **Optimization**: Parallel cleanup operations where possible

### Resource Usage
- **Memory**: Nginx container uses minimal memory (~10-20MB)
- **CPU**: Negligible CPU usage for testing
- **Network**: Minimal bandwidth for mock responses

## Testing Strategy

### Unit Testing

**Script Testing:**
- Test Docker detection (Docker running, not running)
- Test cleanup functionality (existing container, port conflict)
- Test container startup (success, failure scenarios)
- Test signal handling (Ctrl+C, kill signals)
- Test error messages (clarity, helpfulness)

**Nginx Config Testing:**
- Test response to `/s0`, `/s1` paths
- Test response to root path `/`
- Test response to `/s0/update` path
- Test response to unknown paths
- Verify HTTP status codes (200)
- Verify Content-Type headers

### Integration Testing

**End-to-End Testing:**
1. Run `gateway-tunnel-standalone.sh` on server
2. Run `gateway-tunnel-local.sh` on host
3. Test connectivity: `curl http://localhost:9090`
4. Test service path: `curl http://localhost:9090/s0`
5. Verify responses are valid JSON
6. Test cleanup (stop script, verify container removed)

**Runner Integration Testing:**
1. Start standalone gateway
2. Set up SSH tunnel
3. Run `Runner.py -c RunnerParameters-external.json`
4. Verify Runner connects successfully
5. Verify Runner receives responses (even if mock)
6. Verify Runner doesn't crash on mock responses

### User Acceptance Testing

**Setup Time:**
- Measure time from script start to nginx accessible
- Target: < 10 seconds

**Documentation Clarity:**
- Have new user follow documentation
- Measure questions asked
- Target: 0 questions needed

**Error Handling:**
- Test common error scenarios
- Verify error messages are helpful
- Target: User can resolve issues without help

## Deployment Strategy

### File Locations

**Script:**
- `scripts/gateway-tunnel-standalone.sh`
- Executable permissions: `chmod +x`

**Nginx Config:**
- Option 1: `scripts/nginx-standalone.conf` (separate file)
- Option 2: Embedded in script (heredoc)
- Option 3: Generated dynamically in script

**Documentation:**
- `scripts/SSH_TUNNEL_GUIDE.md` (update existing)

### Installation

**No installation required:**
- Script is standalone, no dependencies to install
- Uses standard Docker and nginx images
- No system configuration changes

**First-time Setup:**
- Ensure Docker is installed and running
- Ensure user is in Docker group (or has sudo)
- Pull nginx image: `docker pull nginx` (optional, auto-pulls)

### Usage

**Server-side (gl3):**
```bash
cd /home/ira340/muBench
./scripts/gateway-tunnel-standalone.sh
```

**Host-side:**
```bash
# Use existing script (no changes)
./scripts/gateway-tunnel-local.sh
```

## Risk Assessment

### Risk 1: Port Conflict with Existing Gateway
**Impact**: High - Script fails if port 9090 already in use  
**Probability**: Medium - User might have Kubernetes gateway running  
**Mitigation**: 
- Detect and clean up existing containers/processes
- Provide clear error message with guidance
- Document that user should choose one or the other

### Risk 2: Docker Not Available
**Impact**: High - Script cannot run  
**Probability**: Low - Docker is standard on servers  
**Mitigation**:
- Check Docker availability at start
- Provide clear error message with installation instructions
- Exit gracefully

### Risk 3: Nginx Config Errors
**Impact**: Medium - Container starts but doesn't respond correctly  
**Probability**: Low - Simple nginx config  
**Mitigation**:
- Test nginx config syntax before starting container
- Verify container is responding after start
- Provide troubleshooting steps in documentation

### Risk 4: Runner Compatibility Issues
**Impact**: Medium - Runner might not work with mock responses  
**Probability**: Low - Runner just needs HTTP responses  
**Mitigation**:
- Test Runner with mock responses
- Document limitations clearly
- Provide guidance on interpreting Runner output

### Risk 5: Script Maintenance
**Impact**: Low - Script becomes outdated  
**Probability**: Medium - Over time, patterns may change  
**Mitigation**:
- Follow existing script patterns for consistency
- Add clear comments explaining approach
- Keep script simple and maintainable

## Alternative Approaches Considered

### Alternative 1: Python HTTP Server
**Approach**: Use `python3 -m http.server` instead of nginx  
**Pros**: No Docker required, very simple  
**Cons**: Doesn't match nginx behavior, limited configuration  
**Decision**: Rejected - nginx better matches production setup

### Alternative 2: Docker Compose
**Approach**: Use docker-compose for nginx setup  
**Pros**: More structured, easier to extend  
**Cons**: Additional dependency, more complex  
**Decision**: Rejected - Overkill for simple testing scenario

### Alternative 3: Modify Existing Script
**Approach**: Add standalone mode to `gateway-tunnel.sh`  
**Pros**: Single script, less duplication  
**Cons**: More complex logic, harder to maintain  
**Decision**: Rejected - Separate script is clearer and simpler

### Alternative 4: Systemd Service
**Approach**: Create systemd service for nginx  
**Pros**: More production-like, auto-restart  
**Cons**: Requires system configuration, more complex  
**Decision**: Rejected - Too complex for testing scenario

## Implementation Order

### Phase 1: Core Script (Priority: High)
1. Create `gateway-tunnel-standalone.sh` with basic functionality
2. Implement Docker detection and cleanup
3. Implement container startup
4. Add error handling and signal trapping

### Phase 2: Nginx Configuration (Priority: High)
1. Create mock nginx configuration
2. Test nginx responses to various paths
3. Verify JSON responses are valid
4. Add logging configuration

### Phase 3: Integration Testing (Priority: Medium)
1. Test end-to-end SSH tunnel setup
2. Test Runner connectivity
3. Test cleanup and error scenarios
4. Verify performance targets

### Phase 4: Documentation (Priority: Medium)
1. Update `SSH_TUNNEL_GUIDE.md` with standalone section
2. Add troubleshooting section
3. Document limitations and differences
4. Add examples and test procedures

### Phase 5: Polish (Priority: Low)
1. Improve error messages
2. Add verbose mode option
3. Add health check endpoint
4. Optimize script performance

## Success Criteria

### Technical Success
- [ ] Script starts nginx container in < 5 seconds
- [ ] Script completes setup in < 10 seconds
- [ ] Nginx responds to `/s0` with valid HTTP 200 response
- [ ] Runner can connect and receive responses
- [ ] Script handles all error cases gracefully

### User Success
- [ ] User can set up standalone gateway in < 2 minutes
- [ ] Documentation is clear and complete
- [ ] Error messages are helpful
- [ ] 95% of users succeed on first try

### Integration Success
- [ ] Script coexists with existing `gateway-tunnel.sh`
- [ ] Host-side script works without modification
- [ ] Runner works with mock responses
- [ ] No conflicts with existing scripts

---

**Created:** 2025-01-27  
**Last Updated:** 2025-01-27  
**Status:** Planned  
**Assignee:** TBD  
**Reviewer:** TBD

**Related Documents:**
- [Specification](spec.md) - Detailed requirements
- [Research](research.md) - Initial research and findings
- [SSH Tunnel Guide](../scripts/SSH_TUNNEL_GUIDE.md) - Existing documentation


