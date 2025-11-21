# from typing import Dict, List
# import math

# from .base import TopologyGenerator

# class TreeTopology(TopologyGenerator):
#     def __init__(self, size: str):
#         super().__init__(size)
#         # Define branching factors based on size
#         self.branching_factors = {
#             'small': 2,    # Binary tree
#             'medium': 3,   # Ternary tree
#             'large': 3     # Ternary tree
#         }
        
#     def _get_children_indices(self, parent_idx: int, branching_factor: int) -> List[int]:
#         """Get indices of child nodes for a given parent node."""
#         start_idx = parent_idx * branching_factor + 1
#         return [start_idx + i for i in range(branching_factor) 
#                 if start_idx + i < self.num_services]
    
#     def generate(self) -> Dict:
#         branching_factor = self.branching_factors[self.size]
        
#         # Initialize all services
#         for i in range(self.num_services):
#             self.service_graph[f's{i}'] = {
#                 'external_services': []
#             }
        
#         # Create tree structure
#         for i in range(self.num_services):
#             children = self._get_children_indices(i, branching_factor)
#             if children:
#                 self.service_graph[f's{i}']['external_services'].append({
#                     'seq_len': 100,
#                     'services': [f's{j}' for j in children],
#                     'probabilities': {f's{j}': 1.0/len(children) for j in children}
#                 })
        
#         return self.service_graph 

from typing import Dict, List
import random
from .base import TopologyGenerator

class TreeTopology(TopologyGenerator):
    def __init__(self, size: str, db_access_rate: float = 0.1):
        super().__init__(size)
        self.db_access_rate = db_access_rate
        self.db_node = 'sdb1'

        self.branching_factors = {
            'small': 2,    # Binary tree
            'medium': 3,   # Ternary tree
            'large': 3
        }

    def _get_children_indices(self, parent_idx: int, branching_factor: int) -> List[int]:
        """Get indices of child nodes for a given parent node."""
        start_idx = parent_idx * branching_factor + 1
        return [start_idx + i for i in range(branching_factor) 
                if start_idx + i < self.num_services]

    def _add_db_node(self, leaf_services: List[str]):
        # Step 1: Add the DB node
        self.service_graph[self.db_node] = {
            'external_services': [],
            'db_access': True,
            'path': '/api/v1',
            'url': self.db_node
        }

        # Step 2: Randomly select a few leaf services to access DB
        num_to_connect = max(1, round(len(leaf_services) * self.db_access_rate))
        selected = random.sample(leaf_services, num_to_connect)

        for svc in selected:
            self.service_graph[svc]['external_services'].append({
                'seq_len': 1,
                'services': [self.db_node],
                'probabilities': {self.db_node: 1.0}
            })

    def _merge_external_services(self, service: str):
        merged = {}
        for group in self.service_graph[service]['external_services']:
            for target in group['services']:
                merged[target] = merged.get(target, 0.0) + group['probabilities'][target]
        total = sum(merged.values())
        if total > 0:
            for k in merged:
                merged[k] /= total
        self.service_graph[service]['external_services'] = [{
            'seq_len': 100,
            'services': list(merged.keys()),
            'probabilities': merged
        }]

    def generate(self) -> Dict:
        branching_factor = self.branching_factors[self.size]

        # Step 1: Initialize services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': [],
                'db_access': False,
                'path': '/api/v1',
                'url': f's{i}'
            }

        # Step 2: Build the tree structure
        leaf_nodes = set(f's{i}' for i in range(self.num_services))  # start by assuming all are leafs
        for i in range(self.num_services):
            children = self._get_children_indices(i, branching_factor)
            if children:
                leaf_nodes.discard(f's{i}')  # this node has children, not a leaf
                self.service_graph[f's{i}']['external_services'].append({
                    'seq_len': 100,
                    'services': [f's{j}' for j in children],
                    'probabilities': {f's{j}': 1.0 / len(children) for j in children}
                })

        # Step 3: Add DB access for some leaf nodes
        self._add_db_node(list(leaf_nodes))

        # Step 4: Merge external services (optional, but useful)
        for service in self.service_graph:
            if not self.service_graph[service].get('db_access', False):
                self._merge_external_services(service)

        return self.service_graph
