from typing import Dict
import json
import os
from igraph import Graph, plot

class TopologyGenerator:
    def __init__(self, size: str):
        self.size = size
        self.service_graph = {}
        self.sizes = {
            'small': 5,
            'medium': 12,
            'large': 22
        }
        self.num_services = self.sizes[size]
    
    def generate(self) -> Dict:
        """Generate the service graph topology. Must be implemented by subclasses."""
        raise NotImplementedError
        
    def save_to_file(self, output_dir: str):
        """Save the service graph to a JSON file."""
        os.makedirs(output_dir, exist_ok=True)
        filename = f"servicegraph_{self.__class__.__name__.lower()}_{self.size}.json"
        with open(os.path.join(output_dir, filename), 'w') as f:
            json.dump(self.service_graph, f, indent=2)
        print(f"✅ Generated {filename}")
        
    def visualize(self, output_dir: str):
        """Create and save a visualization of the service graph."""
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
        plot(g, os.path.join(output_dir, "graphs", 
             f"servicegraph_{self.__class__.__name__.lower()}_{self.size}.png"), 
             bbox=(700, 700))
        print(f"✅ Graph visualization saved to {output_dir}/graphs/servicegraph_{self.__class__.__name__.lower()}_{self.size}.png") 