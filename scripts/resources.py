from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient

# Subscription ID
subscription_id = "4d983a20-4949-4708-8e26-36247e4efe50"

# Azure authentication
credential = AzureCliCredential()

# Resource client
resource_client = ResourceManagementClient(
    credential,
    subscription_id
)

print("\nAzure Resources:\n")

# List all resources
for resource in resource_client.resources.list():
    print(f"Name: {resource.name}")
    print(f"Type: {resource.type}")
    print(f"Location: {resource.location}")
    print("-" * 50)