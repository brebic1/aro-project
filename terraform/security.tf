resource "random_password" "postgres_password" {
  length  = 20
  special = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "kv1-algebra-aro"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = false
  
    network_acls {
    default_action = "Deny"
    bypass = "AzureServices"

    virtual_network_subnet_ids = [ 
      azurerm_subnet.appgw_subnet.id,
      azurerm_subnet.jump_subnet.id
    ]

    ip_rules = [
      "193.198.186.130",
      "86.32.214.48"
    ]
  
  }
  access_policy {
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
    "Recover"
    ]


  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Recover"
  ]

  }

  tags = local.tags
}


resource "azurerm_key_vault_secret" "postgres_secret" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_password.result
  key_vault_id = azurerm_key_vault.kv.id

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  location = azurerm_resource_group.rg.location
  name = "aks-identity"
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

resource "azurerm_role_assignment" "aks_kv_access" {
  scope = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
  
}

resource "azurerm_role_assignment" "aks_network" {
  scope = azurerm_virtual_network.vnet_app.id
  role_definition_name = "Network Contributor"
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
  
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_role_assignment" "aks_blob_access" {
  scope = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
}

resource "azurerm_role_assignment" "aks_file_access" {
  scope = azurerm_storage_account.storage.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id = azurerm_user_assigned_identity.aks_identity.principal_id
}


resource "azurerm_user_assigned_identity" "appgw_identity" {
  name = "appgw-identity"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "appgw_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_user_assigned_identity.appgw_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
  certificate_permissions = [
    "Get",
    "List"
  ]
  
}
#resource "azurerm_role_assignment" "appgw_kv_access" {
#  scope = azurerm_key_vault.kv.id
#  role_definition_name = "Key Vault Secrets User"
#  principal_id = azurerm_user_assigned_identity.appgw_identity.principal_id
#}

resource "azurerm_network_security_group" "nsg_jump" {
  name = "nsg_jump"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  security_rule {
    
    name = "allow_rdp_jump"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = "86.32.214.48"
    destination_address_prefix = "*"

  }
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_to_jumpnet" {
  subnet_id = azurerm_subnet.jump_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_jump.id

}

resource "azurerm_role_assignment" "user_blob_access" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "user_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}