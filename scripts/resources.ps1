az resource list --resource-group rg3-algebra-project --query "[].{Name:name,Type:type,Location:location}" -o table
