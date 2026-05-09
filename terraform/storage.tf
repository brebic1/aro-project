resource "azurerm_storage_account" "storage" {
    name = "arostorageacc123456"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    
    network_rules {
        default_action = "Allow"
        bypass = ["AzureServices", "Logging", "Metrics"]
        ip_rules = ["193.198.186.130"]
    }

    public_network_access_enabled = true

    tags = local.tags
}

resource "azurerm_storage_container" "blobst" {
    name = "blobst"
    storage_account_name = azurerm_storage_account.storage.name
    container_access_type = "private"
    
    
}

resource "azurerm_storage_share" "filesha1" {
    name = "filesha1"
    storage_account_name = azurerm_storage_account.storage.name
    quota = 50
}