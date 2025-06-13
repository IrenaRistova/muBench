from typing import Dict, List
import math
from .base import TopologyGenerator

class TieredTopology(TopologyGenerator):
    def __init__(self, size: str):
        super().__init__(size)
        # Define number of tiers based on size
        self.num_tiers = {
            'small': 3,
            'medium': 4,
            'large': 5
        }[size]
        
    def _get_tier_sizes(self) -> List[int]:
        """Calculate the number of services in each tier."""
        remaining = self.num_services
        tier_sizes = []
        
        # First tier (top) always has 1 service
        tier_sizes.append(1)
        remaining -= 1
        
        # Middle tiers get exponentially more services
        for i in range(1, self.num_tiers - 1):
            size = min(2 ** i, remaining)
            tier_sizes.append(size)
            remaining -= size
            
        # Last tier gets remaining services
        if remaining > 0:
            tier_sizes.append(remaining)
            
        return tier_sizes
        
    def generate(self) -> Dict:
        tier_sizes = self._get_tier_sizes()
        current_idx = 0
        
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Connect tiers
        for tier_idx in range(len(tier_sizes) - 1):
            current_tier_size = tier_sizes[tier_idx]
            next_tier_size = tier_sizes[tier_idx + 1]
            
            # Connect each service in current tier to services in next tier
            for i in range(current_tier_size):
                current_service = f's{current_idx + i}'
                next_tier_services = [f's{current_idx + current_tier_size + j}' 
                                    for j in range(next_tier_size)]
                
                if next_tier_services:
                    self.service_graph[current_service]['external_services'].append({
                        'seq_len': 100,
                        'services': next_tier_services,
                        'probabilities': {service: 1.0 / len(next_tier_services) 
                                        for service in next_tier_services}
                    })
            
            current_idx += current_tier_size
        
        return self.service_graph 