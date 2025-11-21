#!/bin/bash

# Script to set up standalone nginx gateway for testing SSH tunnels
# This allows accessing a mock muBench gateway without requiring Kubernetes
# 
# Usage: ./scripts/gateway-tunnel-standalone.sh
#
# Prerequisites:
# 1. Docker installed and running
# 2. User has permission to run Docker commands (or use sudo)
# 3. Port 9090 available on the server

set -e  # Exit on error (we'll handle errors explicitly)

# Configuration
CONTAINER_NAME="mubench-nginx-standalone"
PORT_HOST=9090
PORT_CONTAINER=80
NGINX_IMAGE="nginx:latest"

# Colors for output (optional, fallback if not supported)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is available
check_docker() {
    print_info "Checking Docker availability..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker command not found. Please install Docker."
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        print_error "Cannot connect to Docker daemon."
        print_error "Please ensure Docker is running and you have permission to use it."
        print_error "You may need to:"
        print_error "  - Start Docker: sudo systemctl start docker"
        print_error "  - Add user to docker group: sudo usermod -aG docker $USER"
        print_error "  - Or run this script with sudo"
        exit 1
    fi
    
    print_info "Docker is available and running"
}

# Function to clean up existing containers and processes
cleanup_existing() {
    print_info "Checking for existing containers and processes..."
    
    # Check for existing container
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_warn "Found existing container: ${CONTAINER_NAME}"
        print_info "Stopping and removing existing container..."
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
        print_info "Existing container removed"
    fi
    
    # Check for processes using port 9090
    if command -v fuser &> /dev/null; then
        if fuser -n tcp ${PORT_HOST} &>/dev/null; then
            print_warn "Port ${PORT_HOST} is in use"
            print_info "Attempting to free port ${PORT_HOST}..."
            fuser -k -n tcp ${PORT_HOST} 2>/dev/null || true
            sleep 2
        fi
    elif command -v lsof &> /dev/null; then
        PID=$(lsof -ti:${PORT_HOST} 2>/dev/null || true)
        if [ -n "$PID" ]; then
            print_warn "Port ${PORT_HOST} is in use by PID: $PID"
            print_info "Killing process $PID..."
            kill -9 "$PID" 2>/dev/null || true
            sleep 2
        fi
    else
        print_warn "Cannot check port ${PORT_HOST} (fuser/lsof not available)"
        print_warn "Please ensure port ${PORT_HOST} is available"
    fi
    
    print_info "Cleanup complete"
}

# Function to create nginx configuration
create_nginx_config() {
    local config_file="/tmp/${CONTAINER_NAME}.conf"
    
    cat > "$config_file" << 'EOF'
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;

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
            return 200 '{"status": "ok", "message": "muBench Standalone Gateway", "version": "1.0"}';
            add_header Content-Type application/json;
        }
        
        # Service paths - mock responses for Runner (e.g., /s0, /s1)
        location ~ ^/(s[0-9]+)$ {
            set $service $1;
            return 200 '{"service": "$service", "status": "ok", "message": "Mock response from standalone gateway", "timestamp": "$time_iso8601"}';
            add_header Content-Type application/json;
        }
        
        # Service paths with update endpoint (e.g., /s0/update)
        location ~ ^/(s[0-9]+)/update$ {
            set $service $1;
            return 200 '{"service": "$service", "status": "updated", "message": "Mock update response", "timestamp": "$time_iso8601"}';
            add_header Content-Type application/json;
        }
        
        # Default catch-all
        location / {
            return 200 '{"status": "ok", "path": "$request_uri", "message": "Mock response from standalone gateway"}';
            add_header Content-Type application/json;
        }
    }
}
EOF
    
    echo "$config_file"
}

# Function to start nginx container
start_nginx() {
    print_info "Creating nginx configuration..."
    local config_file=$(create_nginx_config)
    
    print_info "Starting nginx container..."
    print_info "Container name: ${CONTAINER_NAME}"
    print_info "Port mapping: ${PORT_HOST}:${PORT_CONTAINER}"
    
    # Start container with nginx config
    docker run -d \
        --name "${CONTAINER_NAME}" \
        -p "${PORT_HOST}:${PORT_CONTAINER}" \
        -v "${config_file}:/etc/nginx/nginx.conf:ro" \
        "${NGINX_IMAGE}" || {
        print_error "Failed to start nginx container"
        rm -f "$config_file"
        exit 1
    }
    
    # Clean up config file after container starts
    rm -f "$config_file"
    
    print_info "Nginx container started successfully"
}

# Function to verify nginx is running and accessible
verify_nginx() {
    print_info "Verifying nginx container is running..."
    
    # Check container status
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "Container ${CONTAINER_NAME} is not running"
        docker logs "${CONTAINER_NAME}" 2>&1 | tail -20
        exit 1
    fi
    
    print_info "Container is running"
    
    # Wait a moment for nginx to start
    sleep 2
    
    # Test HTTP connectivity
    print_info "Testing HTTP connectivity..."
    if command -v curl &> /dev/null; then
        if curl -s -f "http://localhost:${PORT_HOST}" > /dev/null; then
            print_info "Nginx is accessible on port ${PORT_HOST}"
            
            # Test service path
            if curl -s -f "http://localhost:${PORT_HOST}/s0" > /dev/null; then
                print_info "Service path /s0 is accessible"
            else
                print_warn "Service path /s0 test failed (may still work)"
            fi
        else
            print_error "Nginx is not accessible on port ${PORT_HOST}"
            docker logs "${CONTAINER_NAME}" 2>&1 | tail -20
            exit 1
        fi
    else
        print_warn "curl not available, skipping connectivity test"
        print_info "Please test manually: curl http://localhost:${PORT_HOST}"
    fi
}

# Function to clean up on exit
cleanup_on_exit() {
    print_info "Cleaning up..."
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Stopping container ${CONTAINER_NAME}..."
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    fi
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Removing container ${CONTAINER_NAME}..."
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    fi
    
    # Clean up config file if it exists
    rm -f "/tmp/${CONTAINER_NAME}.conf"
    
    print_info "Cleanup complete"
}

# Trap signals to clean up on exit
trap cleanup_on_exit EXIT INT TERM

# Main execution
main() {
    echo "=========================================="
    echo "  muBench Standalone Gateway Setup"
    echo "=========================================="
    echo ""
    
    check_docker
    cleanup_existing
    start_nginx
    verify_nginx
    
    echo ""
    echo "=========================================="
    print_info "Standalone gateway is ready!"
    echo "=========================================="
    echo ""
    echo "Gateway is accessible at: http://localhost:${PORT_HOST}"
    echo ""
    echo "Test with:"
    echo "  curl http://localhost:${PORT_HOST}"
    echo "  curl http://localhost:${PORT_HOST}/s0"
    echo ""
    echo "On your local machine, set up SSH tunnel with:"
    echo "  ./scripts/gateway-tunnel-local.sh"
    echo ""
    echo "Or manually:"
    echo "  ssh -J glgate@145.108.225.3:42224 -N -L ${PORT_HOST}:localhost:${PORT_HOST} ira340@gl3"
    echo ""
    echo "Then you can test from your host machine:"
    echo "  curl http://localhost:${PORT_HOST}/s0"
    echo ""
    echo "Press Ctrl+C to stop the gateway."
    echo ""
    
    # Wait for user interrupt
    wait
}

# Run main function
main


