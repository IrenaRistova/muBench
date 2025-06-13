from typing import Dict
from .base import TopologyGenerator

class StarTopology(TopologyGenerator):
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Designate the first service as the central node (hub)
        hub = 's0'
        
        # Connect hub to all other services (spokes)
        spokes = [f's{i}' for i in range(1, self.num_services)]
        
        if spokes:
            # Calculate probabilities for the connections from hub to spokes
            total_spokes = len(spokes)
            probabilities = {spoke: 1.0 / total_spokes for spoke in spokes}
            
            # Hub initiates communication to all spokes
            self.service_graph[hub]['external_services'].append({
                'seq_len': 100,
                'services': spokes,
                'probabilities': probabilities
            })
        
        return self.service_graph 