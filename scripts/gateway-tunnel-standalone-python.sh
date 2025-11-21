#!/bin/bash

# Alternative: Python HTTP Server for testing SSH tunnels
# This version doesn't require Docker - uses Python's built-in HTTP server
# 
# Usage: ./scripts/gateway-tunnel-standalone-python.sh
#
# Prerequisites:
# 1. Python 3 installed
# 2. Port 9090 available on the server

set -e

PORT=9090
PID_FILE="/tmp/mubench-standalone-gateway.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

print_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Check if Python 3 is available
check_python() {
    print_info "Checking Python 3 availability..."
    
    # Try multiple ways to find python3
    PYTHON3_CMD=""
    if command -v python3 > /dev/null 2>&1; then
        PYTHON3_CMD="python3"
    elif [ -x /usr/bin/python3 ]; then
        PYTHON3_CMD="/usr/bin/python3"
    elif [ -x /usr/local/bin/python3 ]; then
        PYTHON3_CMD="/usr/local/bin/python3"
    else
        print_error "Python 3 not found. Please install Python 3."
        exit 1
    fi
    
    print_info "Python 3 is available: $($PYTHON3_CMD --version 2>&1)"
}

# Clean up existing process
cleanup_existing() {
    print_info "Checking for existing gateway process..."
    
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            print_warn "Found existing gateway process (PID: $OLD_PID)"
            print_info "Stopping existing process..."
            kill "$OLD_PID" 2>/dev/null || true
            sleep 1
            kill -9 "$OLD_PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    
    # Check for processes using port 9090
    if command -v lsof &> /dev/null; then
        PID=$(lsof -ti:${PORT} 2>/dev/null || true)
        if [ -n "$PID" ]; then
            print_warn "Port ${PORT} is in use by PID: $PID"
            print_info "Killing process $PID..."
            kill "$PID" 2>/dev/null || true
            sleep 1
            kill -9 "$PID" 2>/dev/null || true
        fi
    fi
    
    print_info "Cleanup complete"
}

# Create simple HTTP server script
create_server_script() {
    local script_file="/tmp/mubench_gateway_server.py"
    
    cat > "$script_file" << 'PYEOF'
#!/usr/bin/env python3
"""
Simple HTTP server for muBench standalone gateway testing.
Responds to service paths with mock JSON responses.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from datetime import datetime
import re

class GatewayHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests with mock responses."""
        # Extract service name from path (e.g., /s0 -> s0)
        service_match = re.match(r'^/(s\d+)(?:/update)?/?$', self.path)
        
        if self.path == '/':
            response = {
                "status": "ok",
                "message": "muBench Standalone Gateway (Python)",
                "version": "1.0"
            }
        elif service_match:
            service = service_match.group(1)
            if '/update' in self.path:
                response = {
                    "service": service,
                    "status": "updated",
                    "message": "Mock update response",
                    "timestamp": datetime.now().isoformat()
                }
            else:
                response = {
                    "service": service,
                    "status": "ok",
                    "message": "Mock response from standalone gateway",
                    "timestamp": datetime.now().isoformat()
                }
        else:
            response = {
                "status": "ok",
                "path": self.path,
                "message": "Mock response from standalone gateway"
            }
        
        # Send response
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))
    
    def log_message(self, format, *args):
        """Custom log format."""
        print(f"[STANDALONE-GATEWAY] {self.address_string()} - {format % args}")

def run(port=9090):
    """Run the HTTP server."""
    server_address = ('', port)
    httpd = HTTPServer(server_address, GatewayHandler)
    print(f"muBench Standalone Gateway (Python) running on port {port}")
    print(f"Access at: http://localhost:{port}")
    print(f"Test with: curl http://localhost:{port}/s0")
    print("Press Ctrl+C to stop")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9090
    run(port)
PYEOF
    
    chmod +x "$script_file"
    echo "$script_file"
}

# Start Python HTTP server
start_server() {
    print_info "Creating HTTP server script..."
    local script_file=$(create_server_script)
    
    print_info "Starting Python HTTP server on port ${PORT}..."
    
    # Start server in background (use PYTHON3_CMD if set, otherwise python3)
    ${PYTHON3_CMD:-python3} "$script_file" ${PORT} > /tmp/mubench-gateway.log 2>&1 &
    SERVER_PID=$!
    
    # Save PID
    echo $SERVER_PID > "$PID_FILE"
    
    # Wait a moment for server to start
    sleep 2
    
    # Check if server is still running
    if ! ps -p $SERVER_PID > /dev/null 2>&1; then
        print_error "Server failed to start"
        cat /tmp/mubench-gateway.log
        rm -f "$script_file" "$PID_FILE"
        exit 1
    fi
    
    print_info "HTTP server started (PID: $SERVER_PID)"
}

# Verify server is running
verify_server() {
    print_info "Verifying server is accessible..."
    
    if ! ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        print_error "Server process is not running"
        exit 1
    fi
    
    sleep 1
    
    if command -v curl &> /dev/null; then
        if curl -s -f "http://localhost:${PORT}" > /dev/null; then
            print_info "Server is accessible on port ${PORT}"
            
            # Test service path
            if curl -s -f "http://localhost:${PORT}/s0" > /dev/null; then
                print_info "Service path /s0 is accessible"
            fi
        else
            print_error "Server is not accessible on port ${PORT}"
            cat /tmp/mubench-gateway.log
            exit 1
        fi
    else
        print_warn "curl not available, skipping connectivity test"
    fi
}

# Cleanup on exit
cleanup_on_exit() {
    print_info "Cleaning up..."
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            print_info "Stopping server (PID: $PID)..."
            kill "$PID" 2>/dev/null || true
            sleep 1
            kill -9 "$PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    
    rm -f /tmp/mubench_gateway_server.py
    
    print_info "Cleanup complete"
}

# Trap signals
trap cleanup_on_exit EXIT INT TERM

# Main execution
main() {
    echo "=========================================="
    echo "  muBench Standalone Gateway (Python)"
    echo "=========================================="
    echo ""
    
    check_python
    cleanup_existing
    start_server
    verify_server
    
    echo ""
    echo "=========================================="
    print_info "Standalone gateway is ready!"
    echo "=========================================="
    echo ""
    echo "Gateway is accessible at: http://localhost:${PORT}"
    echo ""
    echo "Test with:"
    echo "  curl http://localhost:${PORT}"
    echo "  curl http://localhost:${PORT}/s0"
    echo ""
    echo "On your local machine, set up SSH tunnel with:"
    echo "  ./scripts/gateway-tunnel-local.sh"
    echo ""
    echo "Or manually:"
    echo "  ssh -J glgate@145.108.225.3:42224 -N -L ${PORT}:localhost:${PORT} ira340@gl3"
    echo ""
    echo "Press Ctrl+C to stop the gateway."
    echo ""
    
    # Wait for user interrupt
    wait
}

main

