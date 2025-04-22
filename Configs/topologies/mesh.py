from typing import Dict
from .base import TopologyGenerator

class MeshTopology(TopologyGenerator):
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Connect all services to each other
        for i in range(self.num_services):
            current_service = f's{i}'
            other_services = [f's{j}' for j in range(self.num_services) if j != i]
            
            if other_services:
                # Calculate probabilities for the connections
                total_connections = len(other_services)
                probabilities = {service: 1.0 / total_connections for service in other_services}
                
                self.service_graph[current_service]['external_services'].append({
                    'seq_len': 100,
                    'services': other_services,
                    'probabilities': probabilities
                })
        
        return self.service_graph 