resource "azurerm_log_analytics_workspace" "log_workspace" {
    name = "log-workspace"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku = "PerGB2018"
    retention_in_days = 30
}
resource "azurerm_virtual_machine_extension" "win_extension" {
    name = "AzureMonitorWindowsAgent"
    virtual_machine_id = azurerm_windows_virtual_machine.jump.id
    publisher = "Microsoft.Azure.Monitor"
    type = "AzureMonitorWindowsAgent"
    type_handler_version = "1.22"
    auto_upgrade_minor_version = true
    tags = local.tags
}
resource "azurerm_monitor_data_collection_rule" "windows_dcr" {
    name                = "windows-dcr"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location

    destinations {
        log_analytics {
            name = "la-dest"
            workspace_resource_id = azurerm_log_analytics_workspace.log_workspace.id
        }
        }

        data_flow {
    destinations = ["la-dest"] 
    streams = ["Microsoft-Perf"] 
    }

        data_flow {
    destinations = ["la-dest"] 
    streams = ["Microsoft-Event"] 
    }

    data_sources {
        performance_counter {
            name = "perf-datasource"
            streams = ["Microsoft-Perf"]
            sampling_frequency_in_seconds = 60
            counter_specifiers = [
                "\\Processor Information(_Total)\\% Processor Time",
                "\\Processor Information(_Total)\\% Privileged Time",
                "\\Processor Information(_Total)\\% User Time",
                "\\Processor Information(_Total)\\Processor Frequency",
                "\\System\\Processes",
                "\\Process(_Total)\\Thread Count",
                "\\Process(_Total)\\Handle Count",
                "\\System\\System Up Time",
                "\\System\\Context Switches/sec",
                "\\System\\Processor Queue Length"
            ]
        }
    windows_event_log {
        name    = "eventLogsDataSource"
        streams = ["Microsoft-Event"]

        x_path_queries = [
        "Security!*[System[(band(Keywords,13510798882111488))]]"
    ]
    
    }

    windows_event_log {
        name    = "eventlog-datasource"
        streams = ["Microsoft-WindowsEvent"]
        x_path_queries = [ 
            "Security!*[System[(Level=1 or Level=2 or Level=3)]]"
            ]
        }
    }
}

resource "azurerm_monitor_data_collection_rule_association" "windows_dcr_association" {
    name = "vm-dcr"
    target_resource_id = azurerm_windows_virtual_machine.jump.id
    data_collection_rule_id = azurerm_monitor_data_collection_rule.windows_dcr.id
    depends_on = [ 
        azurerm_monitor_data_collection_rule.windows_dcr,
        azurerm_virtual_machine_extension.win_extension
    ]
}

resource "azurerm_monitor_diagnostic_setting" "kv_logs" {
    name = "kv-logs"
    target_resource_id = azurerm_key_vault.kv.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
    enabled_log {
        category = "AuditEvent" 
        }
}

resource "azurerm_monitor_diagnostic_setting" "storage_logs" {
    name = "storage-logs"
    target_resource_id = "${azurerm_storage_account.storage.id}/blobServices/default"
    log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id
    enabled_log { 
        category_group = "allLogs" 
        }
    metric { 
        category = "AllMetrics" 
        enabled = true
        }
}

