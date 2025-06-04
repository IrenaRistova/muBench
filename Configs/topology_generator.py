import json
import os
from typing import Dict, List
from igraph import Graph, plot
from topologies import (StarTopology, ChainTopology, MeshTopology, TieredTopology, 
                       DBCentricTopology, TreeTopology, SimpleCycleTopology, ComplexCycleTopology)

class TopologyGenerator:
    def __init__(self, size: str):
        self.size = size
        self.service_graph = {}
        self.sizes = {
            'small': 60,
            'medium': 300,
            'large': 10,
        }
        self.num_services = self.sizes[size]
        
    def generate(self) -> Dict:
        raise NotImplementedError
        
    def save_to_file(self, output_dir: str):
        os.makedirs(output_dir, exist_ok=True)
        filename = f"servicegraph_{self.__class__.__name__.lower()}_{self.size}.json"
        with open(os.path.join(output_dir, filename), 'w') as f:
            json.dump(self.service_graph, f, indent=2)
        print(f"✅ Generated {filename}")
        
    def visualize(self, output_dir: str):
        g = Graph(directed=True)
        node_names = list(self.service_graph.keys())
        g.add_vertices(node_names)
        
        # Add edges
        for src, props in self.service_graph.items():
            for group in props.get("external_services", []):
                for dst in group.get("services", []):
                    if dst not in node_names:
                        g.add_vertices([dst])
                        node_names.append(dst)
                    g.add_edges([(src, dst)])
        
        # Set node visual styles
        g.vs["label"] = g.vs["name"]
        g.vs["color"] = "skyblue"
        g.vs["size"] = 40
        
        # Plot the graph
        os.makedirs(os.path.join(output_dir, "graphs"), exist_ok=True)
        plot(g, os.path.join(output_dir, "graphs", f"servicegraph_{self.__class__.__name__.lower()}_{self.size}.png"), 
             bbox=(700, 700))
        print(f"✅ Graph visualization saved to {output_dir}/graphs/servicegraph_{self.__class__.__name__.lower()}_{self.size}.png")

def generate_all_topologies():
    # Generate Star topologies
    for size in ['small', 'medium', 'large']:
        star = StarTopology(size)
        star.generate()
        star.save_to_file('Star')
        star.visualize('Star')
        
    # Generate Chain topologies
    for size in ['small', 'medium', 'large']:
        chain = ChainTopology(size)
        chain.generate()
        chain.save_to_file('Chain')
        chain.visualize('Chain')
        
    # Generate Mesh topologies
    for size in ['small', 'medium', 'large']:
        mesh = MeshTopology(size)
        mesh.generate()
        mesh.save_to_file('Mesh')
        mesh.visualize('Mesh')
        
    # Generate Tiered topologies
    for size in ['small', 'medium', 'large']:
        tiered = TieredTopology(size)
        tiered.generate()
        tiered.save_to_file('Tiered')
        tiered.visualize('Tiered')
        
    # Generate DB-Centric topologies
    for size in ['small', 'medium', 'large']:
        db_centric = DBCentricTopology(size)
        db_centric.generate()
        db_centric.save_to_file('DB-Centric')
        db_centric.visualize('DB-Centric')
        
    # Generate Tree topologies
    for size in ['small', 'medium', 'large']:
        tree = TreeTopology(size)
        tree.generate()
        tree.save_to_file('Tree')
        tree.visualize('Tree')
        
    # Generate Simple Cycle topologies
    for size in ['small', 'medium', 'large']:
        simple_cycle = SimpleCycleTopology(size)
        simple_cycle.generate()
        simple_cycle.save_to_file('SimpleCycle')
        simple_cycle.visualize('SimpleCycle')
        
    # Generate Complex Cycle topologies
    for size in ['small', 'medium', 'large']:
        complex_cycle = ComplexCycleTopology(size)
        complex_cycle.generate()
        complex_cycle.save_to_file('ComplexCycle')
        complex_cycle.visualize('ComplexCycle')

if __name__ == "__main__":
    generate_all_topologies() 