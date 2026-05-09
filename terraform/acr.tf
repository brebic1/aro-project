resource "azurerm_container_registry" "acr" {
    name = "kmicabananica"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    sku = "Basic"

    tags = local.tags
}

resource "azurerm_kubernetes_cluster" "aks" {
    name = "aro-aks1"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix = "aks1"

    automatic_upgrade_channel = "patch"
    
    default_node_pool {
        name = "default"
        node_count = 1
        vm_size = "standard_b2s"
        vnet_subnet_id = azurerm_subnet.aks_subnet.id
    }

    identity {
        type = "UserAssigned"
        identity_ids = [
            azurerm_user_assigned_identity.aks_identity.id
        ]
    }
    network_profile {
        network_plugin = "azure"
        service_cidr = "172.16.0.0/16"
        dns_service_ip = "172.16.0.10"
    }

    oms_agent {
        log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
        }


    

tags = local.tags

}