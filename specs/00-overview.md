# Project Overview: µBench

## Project Description
µBench is a factory of benchmarking microservice applications. It generates dummy microservice applications that can be customized by users and deployed on Kubernetes. µBench is particularly useful for researchers and cloud platform developers who need real microservice applications to benchmark their findings, such as new resource control mechanisms or AI-driven orchestration.

**Academic Reference**: Detti, A., Funari, L., & Petrucci, L. (2023). µBench: An open-source factory of benchmark microservice applications. IEEE Transactions on Parallel and Distributed Systems. [https://doi.org/10.1109/TPDS.2023.3236447](https://doi.org/10.1109/TPDS.2023.3236447)

## SDD Workflow Guide

This project uses **Spec-Driven Development (SDD)** to structure research tasks and implementations. When working on research tasks, use the SDD commands to create specifications, plans, and tasks.

**For SDD command instructions and workflow guide, see: [README_SDD.md](README_SDD.md)**

## Project Goals

### General Goals
- Generate customizable microservice applications for benchmarking
- Support research in cloud/edge computing platforms
- Enable performance evaluation of microservice architectures
- Provide comprehensive monitoring and observability tools
- Support educational demonstrations of microservice advantages and challenges

### Research Project Goals
- **Deploy existing µBench example topologies** as benchmark applications
- **Evaluate performance and energy efficiency** of different microservice topologies
- **Study system size impact** (5, 10, 20 services) on resource utilization and scalability
- **Provide controlled environment** for topology-based benchmarking
- **Collect and analyze metrics** for performance and energy proxy metrics for comparative analysis
- **Support future extensions** for AI-based orchestration and energy modeling research

### Dataset Goals
- **Build comprehensive benchmarking dataset** for microservice-based systems
- **Create reusable dataset** in dedicated GitHub repository for third-party researchers
- **Systematically generate systems** with different communication topologies (star, chain, ring, random, etc.)
- **Define system families** (8-10 families) with 3 system sizes each (small, medium, large)
- **Enable evaluation** of approaches targeting energy and performance of microservice-based systems

### Research Methodology

**Workload Generation**
- **Tool**: Locust (Python-based load testing framework) ✅ **INTEGRATED**
- **Documentation**: [https://docs.locust.io/](https://docs.locust.io/)
- **Status**: Installed and tested (v2.42.2)
- **Location**: `Benchmarks/Locust/`
- **Execution Location**: Host machine
- **Access Method**: SSH tunnel to muBench gateway (port 9090)
- **Purpose**: Generate controlled HTTP traffic patterns for performance evaluation
- **Integration**: Works with muBench gateway via SSH tunnel
- **Features**:
  - ✅ Stochastic benchmarks (GET requests to ingress services)
  - ✅ Trace-driven benchmarks (POST requests with JSON traces)
  - ✅ Headless mode execution
  - ✅ CSV/JSON metric export
  - ✅ Tested with standalone mock gateway
  - 🔄 Ready for real muBench deployment

**Experiment Orchestration**
- **Tool**: Experiment Runner ([S2-group/experiment-runner](https://github.com/S2-group/experiment-runner))
- **Documentation**: [https://github.com/S2-group/experiment-runner](https://github.com/S2-group/experiment-runner)
- **Purpose**: Automate experiment execution, measurement collection, and data management
- **Features**:
  - Define experiment factors and treatment levels
  - Orchestrate multiple experiment runs
  - Collect and aggregate performance/energy metrics
  - Support experiment restart and recovery
- **Deployment Decision**: **Pending research** - Will determine optimal location (server vs host machine)
  - **Server deployment**: Direct Kubernetes access, lower latency
  - **Host deployment**: Centralized management, easier monitoring
- **Integration Points**:
  - muBench deployment orchestration
  - Locust workload coordination
  - Prometheus metric collection
  - Energy measurement integration (future)

### Research Phases

**Phase 3: Benchmarking**
- **Execution**: Use Experiment Runner to execute each system in random order
- **Execution Guidelines**: Follow Green lab recommendations for server usage
- **Repetitions**: Run each system 30 times for statistical significance
- **System Optimization**: Strip out heavy monitoring infrastructure to reduce overhead
  - muBench generates monitoring infrastructure (Prometheus, Grafana, Istio, etc.)
  - Evaluate which components can be removed without losing essential metrics
- **Metrics Collection**:
  - **Per-Service Metrics**:
    - CPU utilization per service
    - Power consumption per service
  - **System-Wide Metrics**:
    - CPU utilization for the whole server
    - Power consumption for the whole server
  - **Communication Metrics**:
    - Logging of all messages exchanged among services
  - **Data Requirements**:
    - All data must be carefully timestamped
    - Store in CSV format (primary)
    - **BONUS**: Open Telemetry logs format (additional format)

**Experiment Design (Phase 3) - Preliminary Ideas**
> **Note**: These are preliminary ideas and concepts that need further research and validation. The final experiment design will be determined through research and testing.

- **Independent Variables** (preliminary):
  - **Topology** (6 levels): Sequential Fan-out, Parallel Fan-out, Centralized Star, Hierarchical Tree, Probabilistic Tree, Complex Mesh
  - **System Size** (3 levels): 5, 10, 15 services
  - **Replicates**: 30 runs per configuration
- **Controlled Variables** (preliminary):
  - Workload: fixed user load
  - Environment: same server hardware, Minikube setup, container image, gateway configuration
  - Resource limits: same CPU and memory limits, 1 replica per service
  - Measurement duration: 2 min warm-up + 8 min steady load per run
- **Dependent Variables** (preliminary):
  - **Resource Metrics**: CPU and memory usage per service and for full cluster
  - **Performance Metrics** (from Locust): throughput, latency, failures
  - **Energy Metrics** (if available): CPU power consumption, per-service energy data
    - Requires Prometheus and node-level exporters (cAdvisor, node-exporter, RAPL)
- **Automation Workflow** (preliminary concept):
  - Generate 18 unique system configurations (6 topologies × 3 sizes)
  - For each configuration:
    1. Start new Kubernetes namespace for (topology, size, replicate)
    2. Deploy corresponding workmodel via K8sDeployer
    3. Wait until all pods are running
    4. Run Locust workload from host machine (2 min warm-up + 8 min measurement)
       - Execute: `locust -f Benchmarks/Locust/locustfile.py --headless -u <users> -r <spawn_rate> -t 10m --host http://localhost:9090`
       - Verify load traffic visible in Prometheus metrics
       - Adjust `u` (users) and `r` (spawn rate) for desired load intensity
       - ✅ Locust is integrated and ready for use
    5. Collect performance results (throughput, latency) and resource usage (CPU, memory)
    6. Delete namespace and proceed to next configuration

**Phase 4: Usage Showcase**
- **Purpose**: Demonstrate how the dataset can be used in practice
- **Deliverables**:
  - Descriptive statistics on collected data
  - Interesting visualizations and plots
  - Analysis of patterns and relationships in the data
- **Goal**: Provide examples of dataset usage for future researchers

**Phase 5: Reporting and Dataset Packaging**
- **Final Report**:
  - Format: ACM format (max 8 pages, double column)
  - Content: Describe all steps and results from previous phases
  - Sections: Methodology, system families, benchmarking results, dataset structure
- **GitHub Repository**:
  - Polish and finalize dataset repository
  - Include comprehensive documentation
  - Provide usage examples and showcase
  - Reference example: [AndroidTimeMachine/open_source_android_apps](https://github.com/AndroidTimeMachine/open_source_android_apps)
- **Dataset Structure**:
  - Organized by system families
  - Include metadata and documentation
  - Provide data access and usage guidelines

## Architecture Overview

### Core Components

1. **Service-Cell** (`ServiceCell/`)
   - Main software unit implementing each microservice
   - Docker container with Python program
   - Executes internal and external services
   - Supports HTTP REST and gRPC communication

2. **Service Graph Generator** (`ServiceGraphGenerator/`)
   - Generates dependency graphs between microservices
   - Creates service topology configurations
   - Supports various graph patterns (star, chain, tree, etc.)

3. **Work Model Generator** (`WorkModelGenerator/`)
   - Generates work models defining service behaviors
   - Specifies internal service functions (CPU, memory, I/O stress)
   - Defines external service call patterns

4. **K8s Deployer** (`Deployers/K8sDeployer/`)
   - Deploys microservice applications to Kubernetes
   - Generates YAML files for deployments, services, configmaps
   - Manages nginx API gateway

5. **Benchmark Runner** (`Benchmarks/Runner/`)
   - Executes workload tests against deployed applications
   - Supports greedy, periodic, and file-based workload types
   - Collects performance metrics and latency statistics

6. **Monitoring Stack** (`Monitoring/`)
   - Prometheus for metrics collection
   - Grafana for visualization
   - Jaeger for distributed tracing
   - Kiali for service mesh observability
   - Istio service mesh integration

### Key Technologies
- **Container Runtime**: Docker, containerd
- **Orchestration**: Kubernetes (minikube for local development)
- **Service Mesh**: Istio
- **Monitoring**: Prometheus, Grafana, Jaeger, Kiali
- **Languages**: Python 3.8+, YAML, JSON
- **Protocols**: HTTP REST, gRPC

## Current Status
- **Phase**: Active Development
- **Version**: Latest
- **Environment**: Remote server (gl3) with minikube cluster
- **Last Updated**: 2025-01-XX
- **Recent Updates**:
  - ✅ Locust workload generator integrated and tested
  - ✅ SSH tunnel testing setup (standalone mock gateway)
  - 🔄 Experiment Runner integration in progress (basic structure complete, **testing required**)

## Deployment Architecture

### Server Setup (gl3)
- **Kubernetes**: minikube cluster
- **Container Runtime**: Docker with containerd
- **Network**: CNI plugin
- **Access**: SSH through jump host (glgate)

### Service Access
- **API Gateway**: nginx (LoadBalancer service, port 9090 via port-forward)
- **Monitoring**: 
  - Prometheus: Port 30000
  - Grafana: Port 30001
  - Jaeger: Port 30002
  - Kiali: Port 30003

### SSH Tunneling
- Access to services via SSH tunnels from host machine
- Port forwarding scripts in `scripts/` directory
- Gateway and monitoring tunnels configured

### Workload Generation and Experiment Orchestration

**Locust Workload Generator** ✅ **INTEGRATED**
> **Status**: Implemented and tested. Ready for Phase 3 benchmarking.

- **Status**: ✅ Integrated and tested
- **Location**: `Benchmarks/Locust/` on host machine
- **Version**: Locust v2.42.2
- **Purpose**: Generate HTTP workload traffic to muBench applications
- **Documentation**: [https://docs.locust.io/](https://docs.locust.io/)
- **Official Website**: [https://locust.io/](https://locust.io/)
- **Access**: Via SSH tunnel to gateway (port 9090)
- **Usage**: Load testing and performance evaluation
- **Implementation**:
  - ✅ **Installation**: Installed in Python virtual environment
  - ✅ **locustfile.py**: Created with stochastic and trace-driven user classes
  - ✅ **Headless Mode**: Tested and working
  - ✅ **Gateway Integration**: Tested with standalone mock gateway
  - ✅ **Metric Export**: CSV/JSON export supported
- **Execution**:
  - **Command Format**: `locust -f Benchmarks/Locust/locustfile.py --headless -u <users> -r <spawn_rate> -t <duration> --host http://localhost:9090`
  - **Parameters**:
    - `-u` (users): Number of simulated users (e.g., 10, 50, 100)
    - `-r` (spawn rate): Users spawned per second (e.g., 2, 5, 10)
    - `-t` (duration): Test duration (e.g., `10m` for 10 minutes)
    - `--host`: Gateway URL via SSH tunnel (`http://localhost:9090`)
    - `--csv`: Export metrics to CSV files
  - **Workload Patterns**:
    - ✅ Stochastic benchmarks: GET requests to ingress services (s0, s1, etc.)
    - ✅ Trace-driven benchmarks: POST requests with JSON trace body
  - **Test Results**: 
    - GET requests: 198 requests, 0 failures, 3.35 req/s (tested with mock gateway)
    - POST requests: 88 requests, 501 errors (expected with mock gateway - will work with real deployment)
- **Integration** (ready for): 
  - Experiment Runner automation (pending)
  - Runs headless mode for fixed duration (2 min warm-up + 8 min measurement)
  - Collects throughput, latency, and failure metrics
- **References**: 
  - Implementation: `specs/active/locust-workload-setup/feature-brief.md`
  - Gateway tunnel: `scripts/gateway-tunnel.sh` (server) + `scripts/gateway-tunnel-local.sh` (host)
  - Gateway URL: `http://localhost:9090` (via tunnel)
  - Documentation: `Benchmarks/Locust/README.md`

**Experiment Runner** - [GitHub Repository](https://github.com/S2-group/experiment-runner) 🔄 **INTEGRATION IN PROGRESS**
> **Status**: Basic structure complete, testing pending. Deployment and Prometheus integration pending.

- **Status**: 🔄 Integration in progress
- **Location**: `experiment-runner/examples/mubench-benchmarking/` (sibling to muBench)
- **Purpose**: Automatic orchestration of measurement-based experiments
- **Documentation**: [https://github.com/S2-group/experiment-runner](https://github.com/S2-group/experiment-runner)
- **Deployment Location**: **Host machine** (centralized management, easier monitoring)
- **Implementation**:
  - ✅ RunnerConfig.py created with RunTableModel (540 runs)
  - ✅ SSH tunnel integration (before_experiment hook)
  - ✅ Locust execution integration (interact hook)
  - ✅ Locust metric parsing (populate_run_data hook)
  - 🔄 muBench deployment integration (start_run hook - pending)
  - 🔄 Prometheus metric collection (stop_measurement hook - pending)
- **Features**:
  - Run Table Model for defining experiment measurements
  - Factors and Treatment levels support
  - Restart capability for incomplete experiments
  - Persistent storage of raw and aggregated data
  - Progress tracking
- **Automation Workflow**:
  - Control execution of benchmarks from host machine
  - Orchestrate muBench deployments on server (via SSH/Kubernetes API) - pending
  - Run Locust load generator remotely against exposed gateway ✅
  - Collect performance results (throughput, latency) and resource usage (CPU, memory) - partial
  - Manage 18 system configurations × 30 replicates = 540 experiment runs ✅
- **Integration**:
  - ✅ Coordinates Locust workload generation
  - 🔄 Orchestrates muBench deployments (K8sDeployer) - pending
  - 🔄 Collects Prometheus metrics - pending
- **References**:
  - Implementation: `specs/active/experiment-runner-locust-integration/feature-brief.md`
  - Config file: `experiment-runner/examples/mubench-benchmarking/RunnerConfig.py`
  - Status: `specs/active/experiment-runner-locust-integration/CURRENT_STATUS.md`
  - Manages experiment execution workflow
- **References**: 
  - Repository: https://github.com/S2-group/experiment-runner
  - Python-based framework for experiment automation

## Active Features
- Microservice application deployment
- Service graph generation
- Work model generation
- Benchmark execution
- Monitoring and observability

## Completed Features
- Core service-cell implementation
- Kubernetes deployment automation
- Monitoring stack integration
- SSH tunnel setup for remote access

## Backlog Features
- Enhanced autopilot capabilities
- Additional topology patterns
- Performance optimization features
- Extended monitoring capabilities

## Project Structure
```
muBench/
├── ServiceCell/          # Service-cell implementation
├── ServiceGraphGenerator/ # Service graph generation
├── WorkModelGenerator/   # Work model generation
├── Deployers/            # Kubernetes deployment
├── Benchmarks/           # Benchmark runners
├── Monitoring/          # Monitoring stack setup
├── Configs/             # Configuration files
├── Examples/            # Example applications
├── scripts/             # Setup and utility scripts
└── specs/               # SDD specifications (NEW)
```

## Scripts and Utilities

### Setup and Deployment Scripts

**`scripts/setup.sh`** - Main setup script for muBench environment
- **Path**: `scripts/setup.sh`
- **Purpose**: 
  - Starts minikube cluster with optimized configuration (4 CPUs, 8GB RAM)
  - Sets system limits for Istio
  - Creates and configures mubench Docker container
  - Deploys muBench application to Kubernetes
  - Monitors pod status continuously
- **Usage**: `./scripts/setup.sh`
- **References**: 
  - Uses `Configs/K8sParameters.json` for deployment configuration
  - Mounts entire project to `/root/muBench` in container

**`scripts/cleanup.sh`** - Cleanup script for removing all resources
- **Path**: `scripts/cleanup.sh`
- **Purpose**: 
  - Stops and removes all Docker containers, images, volumes, networks
  - Deletes minikube cluster
  - Complete environment cleanup
- **Usage**: `./scripts/cleanup.sh`

### SSH Tunnel Scripts (Remote Access)

**`scripts/monitoring-tunnel.sh`** - Port forwarding for monitoring services (server-side)
- **Path**: `scripts/monitoring-tunnel.sh`
- **Purpose**: 
  - Sets up kubectl port-forward for Prometheus (30000), Grafana (30001), Jaeger (30002), Kiali (30003)
  - Cleans up existing port forwards before starting
  - Provides SSH tunnel command for host machine
- **Usage**: `./scripts/monitoring-tunnel.sh` (run on gl3 server)
- **References**: 
  - Services: `monitoring/prometheus-nodeport`, `monitoring/grafana-nodeport`, `istio-system/jaeger-nodeport`, `istio-system/kiali-nodeport`

**`scripts/monitoring-tunnel-local.sh`** - SSH tunnel for monitoring services (host-side)
- **Path**: `scripts/monitoring-tunnel-local.sh`
- **Purpose**: 
  - Creates SSH tunnel from host machine to gl3 through jump host glgate
  - Forwards ports 30000-30003 for monitoring tools access
- **Usage**: `./scripts/monitoring-tunnel-local.sh` (run on host machine)
- **References**: 
  - Requires `scripts/monitoring-tunnel.sh` to be running on server first

**`scripts/gateway-tunnel.sh`** - Port forwarding for nginx gateway (server-side)
- **Path**: `scripts/gateway-tunnel.sh`
- **Purpose**: 
  - Sets up kubectl port-forward for nginx gateway (port 9090)
  - Allows access to muBench application endpoints
  - Cleans up existing port forwards
- **Usage**: `./scripts/gateway-tunnel.sh` (run on gl3 server)
- **References**: 
  - Service: `svc/gw-nginx` (port 9090:80)
  - Used by: `Benchmarks/Runner/Runner.py` with `RunnerParameters-external.json`

**`scripts/gateway-tunnel-local.sh`** - SSH tunnel for gateway access (host-side)
- **Path**: `scripts/gateway-tunnel-local.sh`
- **Purpose**: 
  - Creates SSH tunnel from host machine for gateway access
  - Forwards port 9090 for application endpoint access
- **Usage**: `./scripts/gateway-tunnel-local.sh` (run on host machine)
- **References**: 
  - Requires `scripts/gateway-tunnel.sh` to be running on server first
  - Used for testing: `curl -v http://localhost:9090/s0`

**`scripts/SSH_TUNNEL_GUIDE.md`** - Complete guide for SSH tunnel setup
- **Path**: `scripts/SSH_TUNNEL_GUIDE.md`
- **Purpose**: 
  - Comprehensive documentation for setting up SSH tunnels
  - Step-by-step instructions for accessing services remotely
  - Troubleshooting guide

## Example Workmodels

### Star Topology Workmodels (Serial and Parallel)

Located in `Examples/` directory. These workmodels use star topology where `s0` calls all other services.

#### Serial Workmodels (Sequential Service Calls)
- **`workmodel-serial-2services.json`** - 2 services (s0, s1)
- **`workmodel-serial-3services.json`** - 3 services (s0, s1, s2)
- **`workmodel-serial-4services.json`** - 4 services (s0, s1, s2, s3)
- **`workmodel-serial-5services.json`** - 5 services (s0, s1, s2, s3, s4)
- **`workmodel-serial-6services.json`** - 6 services (s0, s1, s2, s3, s4, s5)
- **`workmodel-serial-7services.json`** - 7 services (s0, s1, s2, s3, s4, s5, s6)
- **`workmodel-serial-8services.json`** - 8 services (s0, s1, s2, s3, s4, s5, s6, s7)
- **`workmodel-serial-9services.json`** - 9 services (s0, s1, s2, s3, s4, s5, s6, s7, s8)
- **`workmodel-serial-10services.json`** - 10 services (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9)

#### Parallel Workmodels (Parallel Service Calls)
- **`workmodel-parallel-3services.json`** - 3 services (s0, s1, s2)
- **`workmodel-parallel-4services.json`** - 4 services (s0, s1, s2, s3)
- **`workmodel-parallel-5services.json`** - 5 services (s0, s1, s2, s3, s4)
- **`workmodel-parallel-6services.json`** - 6 services (s0, s1, s2, s3, s4, s5)
- **`workmodel-parallel-7services.json`** - 7 services (s0, s1, s2, s3, s4, s5, s6)
- **`workmodel-parallel-8services.json`** - 8 services (s0, s1, s2, s3, s4, s5, s6, s7)
- **`workmodel-parallel-9services.json`** - 9 services (s0, s1, s2, s3, s4, s5, s6, s7, s8)
- **`workmodel-parallel-10services.json`** - 10 services (s0, s1, s2, s3, s4, s5, s6, s7, s8, s9)

### Complex Topology Workmodels (20 Services)

All located in `Examples/` directory with 20 services each:

- **`workmodelA.json`** - 20 services (s0-s19), Topology A pattern
- **`workmodelB.json`** - 20 services (s0-s19), Topology B pattern
- **`workmodelC.json`** - 20 services (s0-s19), Topology C pattern
- **`workmodelC-multi.json`** - 20 services (s0-s19), Topology C with randomness and heterogeneity
- **`workmodelD.json`** - 20 services (s0-s19), Topology D pattern

**Note**: Topology visualizations available in `Examples/servicegraphA.png`, `servicegraphB.png`, `servicegraphC.png`, `servicegraphD.png`

### Specialized Workmodels

- **`Examples/Teastore/workmodel-teastore-emulation.json`** - 6 services (s0-s5)
  - Emulates TeaStore application topology
  - Includes probabilistic service calls

### Alibaba Traces

- **`Examples/Alibaba/traces-mbench.zip`** - Contains 30 applications derived from Alibaba microservice traces
  - Generated using Matlab scripts in `Examples/Alibaba/Matlab/`
  - Includes trace-based workload patterns

### Workmodel Usage

Workmodels are referenced in:
- **`Configs/K8sParameters.json`** - `WorkModelPath` field (default: `Examples/workmodelD.json`)
- **`Deployers/K8sDeployer/RunK8sDeployer.py`** - Reads workmodel to generate Kubernetes deployments
- **`WorkModelGenerator/RunWorkModelGen.py`** - Generates new workmodels

## Key Configuration Files

### Kubernetes Configuration

**`Configs/K8sParameters.json`** - Main Kubernetes deployment configuration
- **Path**: `Configs/K8sParameters.json`
- **Key Settings**:
  - `namespace`: Kubernetes namespace (default: "default")
  - `image`: Docker image for service-cells (`msvcbench/microservice:latest`)
  - `nginx-svc-type`: Service type for gateway ("LoadBalancer" or "NodePort")
  - `WorkModelPath`: Path to workmodel file (default: `Examples/workmodelD.json`)
  - `InternalServiceFilePath`: Path to custom functions (`CustomFunctions`)
  - `OutputPath`: Output directory for generated YAMLs (`SimulationWorkspace`)

### Benchmark Runner Configuration

**`Configs/RunnerParameters.json`** - Benchmark runner config (for server-side execution)
- **Path**: `Configs/RunnerParameters.json`
- **Key Settings**:
  - `ms_access_gateway`: Gateway URL (`http://192.168.49.2:31113` - minikube IP)
  - `workload_type`: "greedy", "periodic", or "file"
  - `workload_events`: Number of requests for greedy/periodic
  - `thread_pool_size`: Concurrent request threads

**`Configs/RunnerParameters-external.json`** - Benchmark runner config (for host-side execution)
- **Path**: `Configs/RunnerParameters-external.json`
- **Key Settings**:
  - `ms_access_gateway`: Gateway URL (`http://localhost:9090` - via SSH tunnel)
  - Used when running benchmarks from host machine with gateway tunnel

### Service Graph Configuration

**`Configs/ServiceGraphParameters.json`** - Service graph generation configuration
- **Path**: `Configs/ServiceGraphParameters.json`
- **Used by**: `ServiceGraphGenerator/RunServiceGraphGen.py`

**`Configs/WorkModelParameters.json`** - Work model generation configuration
- **Path**: `Configs/WorkModelParameters.json`
- **Used by**: `WorkModelGenerator/RunWorkModelGen.py`

## Documentation and References

### Project Documentation
- **µBench Manual**: `Docs/Manual.md` - Complete guide for using µBench
- **µBench README**: `README.md` - Project overview and quick start
- **µBench Repository**: [https://github.com/mSvcBench/muBench](https://github.com/mSvcBench/muBench/tree/main)
- **µBench Docker README**: `Docker-README.md` - Docker container information
- **µBench Paper**: Detti, A., Funari, L., & Petrucci, L. (2023). µBench: An open-source factory of benchmark microservice applications. IEEE Transactions on Parallel and Distributed Systems. [https://doi.org/10.1109/TPDS.2023.3236447](https://doi.org/10.1109/TPDS.2023.3236447)

### External Tools Documentation

**Experiment Runner**
- **Repository**: [https://github.com/S2-group/experiment-runner](https://github.com/S2-group/experiment-runner)
- **Purpose**: Automatic orchestration of measurement-based experiments
- **Documentation**: Available in repository's documentation folder
- **Features**: Run Table Model, Factors/Treatments, experiment restart, data persistence

**Locust** ✅ **INTEGRATED**
- **Official Website**: [https://locust.io/](https://locust.io/)
- **Documentation**: [https://docs.locust.io/](https://docs.locust.io/)
- **Status**: Installed and tested (v2.42.2)
- **Location**: `Benchmarks/Locust/`
- **Purpose**: Python-based load testing framework
- **Usage**: Generate HTTP workload traffic for performance evaluation
- **Implementation**: See `specs/active/locust-workload-setup/feature-brief.md`
- **Documentation**: `Benchmarks/Locust/README.md`

### SDD Workflow Documentation
- [Guidelines](../.sdd/guidelines.md)
- [Configuration](../.sdd/config.json)
- [Templates](../.sdd/templates/)

