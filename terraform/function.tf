resource "azurerm_service_plan" "func" {
    name = "aro-app-service-plan"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    os_type = "Windows"
    sku_name = "B1"

    tags = local.tags
}

resource "azurerm_windows_function_app" "functionapp" {
    name = "aro-windows-function-app"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    storage_account_name = azurerm_storage_account.storage.name
    storage_account_access_key = azurerm_storage_account.storage.primary_access_key
    service_plan_id = azurerm_service_plan.func.id

    virtual_network_subnet_id = azurerm_subnet.function_subnet.id

    

    site_config {
        application_stack {
            powershell_core_version = "7.4"
        }
                ip_restriction {
            ip_address = "86.32.214.48/32"
            action     = "Allow"
            priority   = 100
            name       = "allow-my-ip"
        }

        scm_ip_restriction {
            ip_address = "86.32.214.48/32"
            action     = "Allow"
            priority   = 100
            name       = "allow-my-ip-scm"
        }
        ip_restriction_default_action     = "Deny"
        scm_ip_restriction_default_action = "Deny"
    }
    
    app_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = "powershell"
        website_run_from_package = "1"
    }
    
    tags = local.tags
}