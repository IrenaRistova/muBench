from typing import Dict
from .base import TopologyGenerator

class DBCentricTopology(TopologyGenerator):
    def generate(self) -> Dict:
        # Initialize the DB service
        self.service_graph['sdb1'] = {
            'external_services': []
        }
        
        # Create all other services and connect them to the DB
        for i in range(self.num_services):
            service_name = f's{i}'
            self.service_graph[service_name] = {
                'external_services': [{
                    'seq_len': 100,
                    'services': ['sdb1'],
                    'probabilities': {'sdb1': 1.0}
                }]
            }
        
        return self.service_graph 