import json

# Read the workmodel.json file
with open('SimulationWorkspace/workmodel.json', 'r') as f:
    workmodel = json.load(f)

# Update replicas to 1 for all services
for service in workmodel:
    if 'replicas' in workmodel[service]:
        workmodel[service]['replicas'] = 1

# Write the updated workmodel back to the file
with open('SimulationWorkspace/workmodel.json', 'w') as f:
    json.dump(workmodel, f, indent=2)

print("Updated replicas to 1 for all services in workmodel.json") 