from typing import Dict, List
import random
from .base import TopologyGenerator

class TieredTopology(TopologyGenerator):
    def __init__(self, size: str, db_node_percentage: float = 0.05, db_access_rate: float = 0.15, max_fan_out: int = 3):
        super().__init__(size)

        total_limit = self.sizes[size]
        self.db_node_percentage = db_node_percentage
        self.db_access_rate = db_access_rate
        self.max_fan_out = max_fan_out

        self.num_db_nodes = max(1, round(total_limit * db_node_percentage))
        self.num_services = total_limit - self.num_db_nodes

        self.total_limit = total_limit
        self.num_tiers = {
            'small': 3,
            'medium': 4,
            'large': 6
        }[size]

    def _get_tier_sizes(self) -> List[int]:
        remaining = self.num_services
        tier_sizes = [1]  # First tier always has one entry point
        remaining -= 1

        for i in range(1, self.num_tiers - 1):
            size = min(2 ** i, remaining)
            tier_sizes.append(size)
            remaining -= size

        tier_sizes.append(remaining)  # Add remaining to last tier
        return tier_sizes

    def _add_db_nodes(self, bottom_tier_services: List[str]):
        db_nodes = [f"sdb{i+1}" for i in range(self.num_db_nodes)]

        for db in db_nodes:
            self.service_graph[db] = {
                'external_services': [],
                'db_access': True,
                'path': '/api/v1',
                'url': db
            }

        num_to_connect = max(1, round(len(bottom_tier_services) * self.db_access_rate))
        selected_services = random.sample(bottom_tier_services, num_to_connect)

        # Track which DBs get at least one connection
        dbs_connected = set()

        for service in selected_services:
            db = random.choice(db_nodes)
            dbs_connected.add(db)
            self.service_graph[service]['external_services'].append({
                'seq_len': 1,
                'services': [db],
                'probabilities': {db: 1.0}
            })

        # Ensure every DB node has at least one incoming connection
        unconnected_dbs = set(db_nodes) - dbs_connected
        for db in unconnected_dbs:
            service = random.choice(bottom_tier_services)
            self.service_graph[service]['external_services'].append({
                'seq_len': 1,
                'services': [db],
                'probabilities': {db: 1.0}
            })

    def _merge_external_services(self, service: str):
        """Merge duplicate outgoing edges to the same target for a service."""
        merged = {}
        for group in self.service_graph[service]['external_services']:
            for target in group['services']:
                if target not in merged:
                    merged[target] = 0.0
                merged[target] += group['probabilities'][target]
        # Normalize probabilities
        total = sum(merged.values())
        if total > 0:
            for k in merged:
                merged[k] /= total
        # Replace with a single group
        self.service_graph[service]['external_services'] = [{
            'seq_len': 100,
            'services': list(merged.keys()),
            'probabilities': merged
        }]

    def generate(self) -> Dict:
        tier_sizes = self._get_tier_sizes()
        current_idx = 0
        tiers = []

        # Step 1: Initialize services and assign them to tiers
        for size in tier_sizes:
            tier = []
            for _ in range(size):
                name = f's{current_idx}'
                self.service_graph[name] = {
                    'external_services': [],
                    'db_access': False,
                    'path': '/api/v1',
                    'url': name
                }
                tier.append(name)
                current_idx += 1
            tiers.append(tier)

        # Step 2: Ensure full connectivity and random fan-out
        for i in range(len(tiers) - 1):
            current_tier = tiers[i]
            next_tier = tiers[i + 1]

            # Guarantee: every service in next_tier has at least one incoming edge
            for target in next_tier:
                source = random.choice(current_tier)
                self.service_graph[source]['external_services'].append({
                    'seq_len': 100,
                    'services': [target],
                    'probabilities': {target: 1.0}
                })

            # Random fan-out: add more realistic extra edges
            for source in current_tier:
                targets = random.sample(next_tier, k=random.randint(1, min(len(next_tier), self.max_fan_out)))
                self.service_graph[source]['external_services'].append({
                    'seq_len': 100,
                    'services': targets,
                    'probabilities': {t: 1.0 / len(targets) for t in targets}
                })

        # Step 3: Add DB access to some bottom-tier services
        self._add_db_nodes(tiers[-1])

        # Step 4: Merge duplicate outgoing edges for each service
        for service in self.service_graph:
            if not self.service_graph[service].get('db_access', False):
                self._merge_external_services(service)

        return self.service_graph
