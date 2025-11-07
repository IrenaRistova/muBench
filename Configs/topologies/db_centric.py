# from typing import Dict
# from .base import TopologyGenerator

# class DBCentricTopology(TopologyGenerator):
#     def generate(self) -> Dict:
#         # Initialize the DB service
#         self.service_graph['sdb1'] = {
#             'external_services': []
#         }
        
#         # Create all other services and connect them to the DB
#         for i in range(self.num_services):
#             service_name = f's{i}'
#             self.service_graph[service_name] = {
#                 'external_services': [{
#                     'seq_len': 100,
#                     'services': ['sdb1'],
#                     'probabilities': {'sdb1': 1.0}
#                 }]
#             }
        
#         return self.service_graph 

from typing import Dict
import random
from .base import TopologyGenerator

class DBCentricTopology(TopologyGenerator):
    def __init__(self, size: str, db_access_rate: float = 0.5, seed: int = 42):
        super().__init__(size)
        self.db_node = 'sdb1'
        self.db_access_rate = db_access_rate
        self.random = random.Random(seed)

    def generate(self) -> Dict:
        # Init all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': [],
                'path': '/api/v1',
                'url': f's{i}',
                'db_access': False
            }

        # Add DB node
        self.service_graph[self.db_node] = {
            'external_services': [],
            'path': '/api/v1',
            'url': self.db_node,
            'db_access': True
        }

        # s0 is the NGINX-like entrypoint – it only sends traffic
        entry_targets = [f's{j}' for j in range(1, min(4, self.num_services))]
        self.service_graph['s0']['external_services'].append({
            'seq_len': 100,
            'services': entry_targets,
            'probabilities': {t: 1.0 / len(entry_targets) for t in entry_targets}
        })

        # Create random processing flow among s1 to s{n-1}
        for i in range(1, self.num_services):
            num_targets = self.random.randint(1, 3)
            possible_targets = [j for j in range(i + 1, self.num_services) if j != i]
            if not possible_targets:
                continue
            targets = self.random.sample(possible_targets, min(num_targets, len(possible_targets)))
            services = [f's{t}' for t in targets]
            probs = {s: 1.0 / len(services) for s in services}
            self.service_graph[f's{i}']['external_services'].append({
                'seq_len': 100,
                'services': services,
                'probabilities': probs
            })

        # Add DB access to random services
        db_candidates = [f's{i}' for i in range(1, self.num_services)]
        num_db_users = max(1, round(len(db_candidates) * self.db_access_rate))
        selected = self.random.sample(db_candidates, num_db_users)
        for svc in selected:
            self.service_graph[svc]['external_services'].append({
                'seq_len': 1,
                'services': [self.db_node],
                'probabilities': {self.db_node: 1.0}
            })

        return self.service_graph
