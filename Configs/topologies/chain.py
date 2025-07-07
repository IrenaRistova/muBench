# from typing import Dict
# from .base import TopologyGenerator

# class ChainTopology(TopologyGenerator):
#     def generate(self) -> Dict:
#         # Initialize all services
#         for i in range(self.num_services):
#             self.service_graph[f's{i}'] = {
#                 'external_services': []
#             }
        
#         # Connect each service to the next one in the chain
#         for i in range(self.num_services - 1):
#             current_service = f's{i}'
#             next_service = f's{i + 1}'
            
#             self.service_graph[current_service]['external_services'].append({
#                 'seq_len': 100,
#                 'services': [next_service],
#                 'probabilities': {next_service: 1.0}
#             })
        
#         return self.service_graph 

from typing import Dict, List
import random
from .base import TopologyGenerator

class ChainTopology(TopologyGenerator):
    def __init__(self, size: str, db_access_rate: float = 0.03, branch_prob: float = 0.2):
        super().__init__(size)
        self.db_access_rate = db_access_rate
        self.branch_prob = branch_prob
        self.num_services = self.sizes[size] - 1  # reserve 1 for DB
        self.db_node = 'sdb1'

    def _add_db_node(self, candidate_services: List[str]):
        self.service_graph[self.db_node] = {
            'external_services': [],
            'db_access': True,
            'path': '/api/v1',
            'url': self.db_node
        }

        num_to_connect = max(1, round(len(candidate_services) * self.db_access_rate))
        selected_services = random.sample(candidate_services, num_to_connect)

        for service in selected_services:
            self.service_graph[service]['external_services'].append({
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
        # Step 1: Init services
        for i in range(self.num_services):
            name = f's{i}'
            self.service_graph[name] = {
                'external_services': [],
                'db_access': False,
                'path': '/api/v1',
                'url': name
            }

        # Step 2: Chain backbone
        for i in range(self.num_services - 1):
            src, dst = f's{i}', f's{i+1}'
            self.service_graph[src]['external_services'].append({
                'seq_len': 100,
                'services': [dst],
                'probabilities': {dst: 1.0}
            })

        # Step 3: Short forward branches (only 2 steps max forward)
        for i in range(self.num_services - 2):
            if random.random() < self.branch_prob:
                src = f's{i}'
                dst_candidates = [f's{j}' for j in range(i + 2, min(i + 3, self.num_services))]
                if dst_candidates:
                    dst = random.choice(dst_candidates)
                    self.service_graph[src]['external_services'].append({
                        'seq_len': 100,
                        'services': [dst],
                        'probabilities': {dst: 1.0}
                    })

        # Step 4: Realistic DB access (from anywhere except entry point)
        eligible_for_db = [f's{i}' for i in range(1, self.num_services)]
        self._add_db_node(eligible_for_db)

        # Step 5: Merge outgoing edges
        for service in self.service_graph:
            if not self.service_graph[service].get('db_access', False):
                self._merge_external_services(service)

        return self.service_graph
