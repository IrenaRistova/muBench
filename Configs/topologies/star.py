# from typing import Dict
# from .base import TopologyGenerator

# class StarTopology(TopologyGenerator):
#     def generate(self) -> Dict:
#         # Initialize all services
#         for i in range(self.num_services):
#             self.service_graph[f's{i}'] = {
#                 'external_services': []
#             }
        
#         # Designate the first service as the central node (hub)
#         hub = 's0'
        
#         # Connect hub to all other services (spokes)
#         spokes = [f's{i}' for i in range(1, self.num_services)]
        
#         if spokes:
#             # Calculate probabilities for the connections from hub to spokes
#             total_spokes = len(spokes)
#             probabilities = {spoke: 1.0 / total_spokes for spoke in spokes}
            
#             # Hub initiates communication to all spokes
#             self.service_graph[hub]['external_services'].append({
#                 'seq_len': 100,
#                 'services': spokes,
#                 'probabilities': probabilities
#             })
        
#         return self.service_graph 

from typing import Dict, List
import random
from .base import TopologyGenerator

class StarTopology(TopologyGenerator):
    def __init__(self, size: str, db_access_rate: float = 0.07, lateral_prob: float = 0.1):
        super().__init__(size)
        self.db_access_rate = db_access_rate
        self.lateral_prob = lateral_prob
        self.db_node = 'sdb1'

    def _add_db_node(self, services: List[str]):
        # Add DB node
        self.service_graph[self.db_node] = {
            'external_services': [],
            'db_access': True,
            'path': '/api/v1',
            'url': self.db_node
        }

        # Randomly select a subset of services to access DB
        num_to_connect = max(1, round(len(services) * self.db_access_rate))
        selected = random.sample(services, num_to_connect)

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
        # Step 1: Initialize services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': [],
                'db_access': False,
                'path': '/api/v1',
                'url': f's{i}'
            }

        hub = 's0'
        spokes = [f's{i}' for i in range(1, self.num_services)]

        # Step 2: Hub connects to all spokes
        probabilities = {spoke: 1.0 / len(spokes) for spoke in spokes}
        self.service_graph[hub]['external_services'].append({
            'seq_len': 100,
            'services': spokes,
            'probabilities': probabilities
        })

        # Step 3: Add lateral edges between spokes (avoid cycles to hub)
        for i in range(len(spokes)):
            for j in range(i + 1, len(spokes)):
                if random.random() < self.lateral_prob:
                    source = spokes[i]
                    target = spokes[j]
                    self.service_graph[source]['external_services'].append({
                        'seq_len': 100,
                        'services': [target],
                        'probabilities': {target: 1.0}
                    })

        # Step 4: Add DB node and connect some spokes to it
        self._add_db_node(spokes)

        # Step 5: Merge duplicate edges
        for svc in self.service_graph:
            if not self.service_graph[svc].get('db_access', False):
                self._merge_external_services(svc)

        return self.service_graph
