#database type shit: posgresql server, database 

resource "azurerm_private_dns_zone" "sql_dns" {
    name = "privatelink.postgres.database.azure.com"
    resource_group_name = azurerm_resource_group.rg.name

    tags = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
    name = "sql_dns_link"
    private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
    virtual_network_id = azurerm_virtual_network.vnet_app.id
    resource_group_name = azurerm_resource_group.rg.name
    depends_on = [ azurerm_private_dns_zone.sql_dns ]

    tags = local.tags
}
resource "azurerm_postgresql_flexible_server" "postsql" {
    name                   = "postsql-server"
    resource_group_name    = azurerm_resource_group.rg.name
    location               = azurerm_resource_group.rg.location
    version                = "13"
    delegated_subnet_id    = azurerm_subnet.db_subnet.id
    private_dns_zone_id    = azurerm_private_dns_zone.sql_dns.id
    administrator_login    = "adminterraform"
    administrator_password = azurerm_key_vault_secret.postgres_secret.value
    public_network_access_enabled = false
    
    sku_name = "B_Standard_B1ms"
    zone = "1"
    depends_on = [ azurerm_private_dns_zone_virtual_network_link.sql_dns_link ]

    backup_retention_days = "7"

    tags = local.tags

}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link_jump" {
    name                  = "sql-dns-link-jump"
    resource_group_name   = azurerm_resource_group.rg.name
    private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
    virtual_network_id    = azurerm_virtual_network.vnet_jump.id
}