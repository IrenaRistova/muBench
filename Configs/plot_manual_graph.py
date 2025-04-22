import json
from igraph import Graph, plot
import os

# Load your manual servicegraph.json
with open("./Star/servicegraph_star_large_manual.json") as f:
    graph_data = json.load(f)

g = Graph(directed=True)
node_names = list(graph_data.keys())
g.add_vertices(node_names)

# Add edges
for src, props in graph_data.items():
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
os.makedirs("graphs", exist_ok=True)
plot(g, "Star/graphs/servicegraph_star_large_manual.png", bbox=(700, 700))
print("✅ Graph saved to graphs/servicegraph_star_small_manual.png")
