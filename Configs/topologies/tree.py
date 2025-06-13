from typing import Dict, List
import math

from .base import TopologyGenerator

class TreeTopology(TopologyGenerator):
    def __init__(self, size: str):
        super().__init__(size)
        # Define branching factors based on size
        self.branching_factors = {
            'small': 2,    # Binary tree
            'medium': 3,   # Ternary tree
            'large': 3     # Ternary tree
        }
        
    def _get_children_indices(self, parent_idx: int, branching_factor: int) -> List[int]:
        """Get indices of child nodes for a given parent node."""
        start_idx = parent_idx * branching_factor + 1
        return [start_idx + i for i in range(branching_factor) 
                if start_idx + i < self.num_services]
    
    def generate(self) -> Dict:
        branching_factor = self.branching_factors[self.size]
        
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Create tree structure
        for i in range(self.num_services):
            children = self._get_children_indices(i, branching_factor)
            if children:
                self.service_graph[f's{i}']['external_services'].append({
                    'seq_len': 100,
                    'services': [f's{j}' for j in children],
                    'probabilities': {f's{j}': 1.0/len(children) for j in children}
                })
        
        return self.service_graph 