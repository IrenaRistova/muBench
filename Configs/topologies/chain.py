from typing import Dict
from .base import TopologyGenerator

class ChainTopology(TopologyGenerator):
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Connect each service to the next one in the chain
        for i in range(self.num_services - 1):
            current_service = f's{i}'
            next_service = f's{i + 1}'
            
            self.service_graph[current_service]['external_services'].append({
                'seq_len': 100,
                'services': [next_service],
                'probabilities': {next_service: 1.0}
            })
        
        return self.service_graph 