# Topology Generator

This directory contains the topology generator for creating different microservice architectures. The generator creates both JSON configuration files and visual graph representations for each topology type and size.

## Structure

### Main Generator
- `topology_generator.py`: Main script that generates all topologies

### Base Class
- `TopologyGenerator` (in `topologies/base.py`): Parent class that all topologies inherit from

### Topology Types
Located in `topologies/` directory:
- `StarTopology`: Central service with connections to all others
- `ChainTopology`: Linear sequence of connected services
- `MeshTopology`: Every service connects to every other service
- `TieredTopology`: Services organized in layers
- `DBCentricTopology`: Database service with connections to all other services
- `TreeTopology`: Hierarchical structure with branching
- `SimpleCycleTopology`: Basic circular connections
- `ComplexCycleTopology`: Multiple overlapping cycles with orchestration

### Output Files
For each topology and size (small, medium, large):
- JSON files: `servicegraph_[topology]_[size].json`
- Graph visualizations: `servicegraph_[topology]_[size].png`

## Usage

To generate all topologies:
```bash
python3 topology_generator.py
```

This will create the necessary JSON configuration files and graph visualizations for each topology type and size. 