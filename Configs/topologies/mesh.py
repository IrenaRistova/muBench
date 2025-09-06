from typing import Dict
import random
from .base import TopologyGenerator

class MeshTopology(TopologyGenerator):
    def __init__(self, size: str):
        super().__init__(size)
        # Define connection limits based on size
        self.config = {
            'small': {
                'min_out_degree': 5,    # Minimum out-degree of 5 as per Alibaba's analysis
                'max_out_degree': 12,   # Higher max out-degree for dense connections
                'high_connectivity_ratio': 0.1,  # 10% of services are highly connected
                'high_connectivity_degree': 16,  # High connectivity services have up to 16 connections
                'cluster_size': 15      # Larger clusters for more interaction opportunities
            },
            'medium': {
                'min_out_degree': 6,
                'max_out_degree': 15,
                'high_connectivity_ratio': 0.15,
                'high_connectivity_degree': 20,
                'cluster_size': 25
            },
            'large': {
                'min_out_degree': 7,
                'max_out_degree': 18,
                'high_connectivity_ratio': 0.2,
                'high_connectivity_degree': 25,
                'cluster_size': 35
            }
        }
    
    def generate(self) -> Dict:
        # Initialize all services
        for i in range(self.num_services):
            self.service_graph[f's{i}'] = {
                'external_services': []
            }
        
        # Create natural clusters
        config = self.config[self.size]
        clusters = []
        remaining_services = list(range(self.num_services))
        
        # Create clusters
        while remaining_services:
            cluster_size = min(config['cluster_size'], len(remaining_services))
            cluster = random.sample(remaining_services, cluster_size)
            clusters.append(cluster)
            remaining_services = [s for s in remaining_services if s not in cluster]
        
        # Identify highly connected services (10-20% of services)
        num_high_connectivity = int(self.num_services * config['high_connectivity_ratio'])
        high_connectivity_services = random.sample(range(self.num_services), num_high_connectivity)
        
        # Connect services within clusters and create dense interactions
        for cluster in clusters:
            for service_idx in cluster:
                current_service = f's{service_idx}'
                
                # Determine if this is a highly connected service
                is_high_connectivity = service_idx in high_connectivity_services
                
                # Get potential connection targets
                # For highly connected services, consider all services
                if is_high_connectivity:
                    potential_targets = [f's{j}' for j in range(self.num_services) if j != service_idx]
                else:
                    # For regular services, focus on cluster connections but allow some cross-cluster
                    cluster_targets = [f's{j}' for j in cluster if j != service_idx]
                    other_clusters = [c for c in clusters if service_idx not in c]
                    cross_cluster_targets = []
                    for other_cluster in other_clusters:
                        # Add some cross-cluster connections
                        num_cross = random.randint(1, 3)
                        cross_cluster_targets.extend(
                            [f's{j}' for j in random.sample(other_cluster, num_cross)]
                        )
                    potential_targets = cluster_targets + cross_cluster_targets
                
                # Determine number of connections
                available_targets = len(potential_targets)
                min_degree = min(config['min_out_degree'], available_targets)
                if is_high_connectivity:
                    max_degree = min(config['high_connectivity_degree'], available_targets)
                else:
                    max_degree = min(config['max_out_degree'], available_targets)
                if available_targets > 0 and min_degree <= max_degree:
                    num_connections = random.randint(min_degree, max_degree)
                    # Select random services to connect to
                    selected_services = random.sample(potential_targets, num_connections)
                    # Add connections with equal probabilities
                    if selected_services:
                        probabilities = {service: 1.0 / len(selected_services) 
                                    for service in selected_services}
                        self.service_graph[current_service]['external_services'].append({
                            'seq_len': 100,
                            'services': selected_services,
                            'probabilities': probabilities
                        })
        
        # Ensure additional cross-cluster connections for highly connected services
        for service_idx in high_connectivity_services:
            current_service = f's{service_idx}'
            # Find services not yet connected to this highly connected service
            existing_connections = set()
            for group in self.service_graph[current_service]['external_services']:
                existing_connections.update(group['services'])
            
            # Add more connections to other clusters
            for cluster in clusters:
                if service_idx not in cluster:
                    # Add 1-3 more connections to this cluster
                    num_additional = random.randint(1, 3)
                    potential_new = [f's{j}' for j in cluster 
                                   if f's{j}' not in existing_connections]
                    if potential_new:
                        new_connections = random.sample(potential_new, 
                                                     min(num_additional, len(potential_new)))
                        if new_connections:
                            probabilities = {service: 1.0 / len(new_connections) 
                                           for service in new_connections}
                            self.service_graph[current_service]['external_services'].append({
                                'seq_len': 100,
                                'services': new_connections,
                                'probabilities': probabilities
                            })
        
        # --- DB Access Integration ---
        db_access_rate = random.uniform(0.02, 0.05)  # 2–5%
        num_db_services = int(self.num_services * db_access_rate)
        # Enforce minimums for realism
        if self.num_services <= 100:
            num_db_services = max(3, num_db_services)
        elif self.num_services < 1000:
            num_db_services = max(5, num_db_services)
        # Exclude 's0' from being a DB
        possible_db_services = [s for s in self.service_graph.keys() if s != 's0']
        db_services = random.sample(possible_db_services, num_db_services)
        db_rename_map = {s: f"db{s[1:]}" for s in db_services}
        new_service_graph = {}
        # Rename services and set db_access
        for service in self.service_graph:
            if service in db_services:
                new_name = db_rename_map[service]
                entry = self.service_graph[service]
                entry['db_access'] = True
                new_service_graph[new_name] = entry
            else:
                entry = self.service_graph[service]
                entry['db_access'] = False
                new_service_graph[service] = entry
        # Update all references in external_services
        for service in new_service_graph:
            for group in new_service_graph[service]['external_services']:
                group['services'] = [db_rename_map.get(s, s) for s in group['services']]
                group['probabilities'] = {db_rename_map.get(k, k): v for k, v in group['probabilities'].items()}
        self.service_graph = new_service_graph
        return self.service_graph 