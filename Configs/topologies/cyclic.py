from typing import Dict, List
import random
from .base import TopologyGenerator

class SimpleCycleTopology(TopologyGenerator):
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Create a simple cycle where each service connects to the next one
        for i in range(self.num_services):
            next_service = f's{(i + 1) % self.num_services}'
            self.service_graph[f's{i}']['external_services'].append({
                'seq_len': 100,
                'services': [next_service],
                'probabilities': {next_service: 1.0}
            })
        
        return self.service_graph

class ComplexCycleTopology(TopologyGenerator):
    def __init__(self, size: str):
        super().__init__(size)
        # Define number of cycles and orchestration services based on size
        self.config = {
            'small': {
                'num_cycles': 2,
                'num_orchestrators': 1,
                'max_fan_out': 3,
                'max_fan_in': 2,
                'min_cycle_length': 3,
                'max_cycle_length': 4
            },
            'medium': {
                'num_cycles': 3,
                'num_orchestrators': 2,
                'max_fan_out': 4,
                'max_fan_in': 3,
                'min_cycle_length': 3,
                'max_cycle_length': 5
            },
            'large': {
                'num_cycles': 4,
                'num_orchestrators': 3,
                'max_fan_out': 5,
                'max_fan_in': 4,
                'min_cycle_length': 3,
                'max_cycle_length': 6
            }
        }
    
    def _create_cycle(self, start_idx: int, cycle_length: int) -> List[int]:
        """Create a cycle of specified length starting from start_idx."""
        cycle_nodes = []
        current = start_idx
        for _ in range(cycle_length):
            cycle_nodes.append(current)
            current = (current + 1) % self.num_services
        return cycle_nodes
    
    def _add_orchestrator_connections(self, orchestrator_idx: int):
        """Add connections for an orchestrator service."""
        # Orchestrators typically have high fan-out
        fan_out = random.randint(2, self.config[self.size]['max_fan_out'])
        targets = random.sample(range(self.num_services), fan_out)
        
        for target in targets:
            if target != orchestrator_idx:
                self.service_graph[f's{orchestrator_idx}']['external_services'].append({
                    'seq_len': 100,
                    'services': [f's{target}'],
                    'probabilities': {f's{target}': 1.0}
                })
    
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Create multiple overlapping cycles
        cycle_lengths = []
        config = self.config[self.size]
        for _ in range(config['num_cycles']):
            # Ensure cycle length is valid
            min_length = config['min_cycle_length']
            max_length = min(config['max_cycle_length'], self.num_services - 1)
            if min_length <= max_length:
                length = random.randint(min_length, max_length)
                cycle_lengths.append(length)
        
        # Create cycles with random starting points
        used_nodes = set()
        for cycle_length in cycle_lengths:
            # Find a starting point that's not already in too many cycles
            start_candidates = [i for i in range(self.num_services) 
                              if len([n for n in used_nodes if n == i]) < 2]
            if not start_candidates:
                break
                
            start_idx = random.choice(start_candidates)
            cycle_nodes = self._create_cycle(start_idx, cycle_length)
            used_nodes.update(cycle_nodes)
            
            # Add connections for this cycle
            for i in range(len(cycle_nodes)):
                current = cycle_nodes[i]
                next_node = cycle_nodes[(i + 1) % len(cycle_nodes)]
                
                # Add connection with some probability to create gaps
                if random.random() < 0.8:  # 80% chance to add connection
                    self.service_graph[f's{current}']['external_services'].append({
                        'seq_len': 100,
                        'services': [f's{next_node}'],
                        'probabilities': {f's{next_node}': 1.0}
                    })
        
        # Add orchestration services
        orchestrators = random.sample(range(self.num_services), 
                                    config['num_orchestrators'])
        for orchestrator in orchestrators:
            self._add_orchestrator_connections(orchestrator)
        
        # Add some random fan-in connections to create more complex patterns
        for _ in range(self.num_services // 2):
            target = random.randint(0, self.num_services - 1)
            fan_in = random.randint(1, config['max_fan_in'])
            sources = random.sample([i for i in range(self.num_services) if i != target], 
                                  min(fan_in, self.num_services - 1))
            
            for source in sources:
                self.service_graph[f's{source}']['external_services'].append({
                    'seq_len': 100,
                    'services': [f's{target}'],
                    'probabilities': {f's{target}': 1.0}
                })
        
        # Normalize probabilities for services with multiple outgoing connections
        for service in self.service_graph.values():
            if len(service['external_services']) > 1:
                total_prob = sum(1.0 for group in service['external_services'] 
                               for _ in group['services'])
                for group in service['external_services']:
                    for service_name in group['services']:
                        group['probabilities'][service_name] = 1.0 / total_prob
        
        return self.service_graph 