resource "random_uuid" "workbook_uuid" {}

resource "azurerm_application_insights_workbook" "aro_workbook" {
    name = random_uuid.workbook_uuid.result
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    source_id = lower(azurerm_log_analytics_workspace.log_workspace.id)
    display_name = "aro-workbook"
    
    data_json = jsonencode({
        version = "Notebook/1.0"
        items = [
            {
                type = 3
                content = {
                    version = "KqlItem/1.0"
                    resource_type = "microsoft.operationalinsights/workspaces"
                    display_name = "CPU Performance"
                    query = "Perf | where CounterName == \"% Processor Time\" | summarize avg(CounterValue) by bin(TimeGenerated, 5m)"
                    title = "CPU Performance"
                    visualization = "timechart"
                }
            },    
            {
                type = 3

                content = {
                    version = "KqlItem/1.0"
                    resource_type = "microsoft.operationalinsights/workspaces"
                    display_name = "VM logs"
                    query = "Event | take 10"
                    title = "VM Logs"
                }
            },
            {
                type = 3
                content = {
                    version = "KqlItem/1.0"
                    resource_type = "microsoft.operationalinsights/workspaces"
                    display_name = "AKS logs"
                    query = "ContainerLog | take 10"
                    title = "Container Logs"
            }
            },
            {
                type = 3
                content = {
                    version = "KqlItem/1.0"
                    resource_type = "microsoft.operationalinsights/workspaces"
                    display_name = "Storage logs"
                    query = "StorageBlobLogs | where OperationName in ('GetBlob', 'PutBlob', 'DeleteBlob', 'ListBlobs') | order by TimeGenerated desc | take 10"
                    title = "Storage Logs"
            }
            },
            {
                type = 3
                content = {
                    version = "KqlItem/1.0"
                    resource_type = "microsoft.operationalinsights/workspaces"
                    display_name = "Key Vault logs"
                    query = "AzureDiagnostics | where ResourceProvider == \"MICROSOFT.KEYVAULT\" | order by TimeGenerated desc | take 10"
                    title = "Key Vault Logs"
            }
            }
        
        ]
    })
    tags = local.tags

    depends_on = [ 
        azurerm_log_analytics_workspace.log_workspace,
        azurerm_monitor_data_collection_rule.windows_dcr,
        azurerm_monitor_data_collection_rule_association.windows_dcr_association,
        azurerm_monitor_diagnostic_setting.storage_logs,
        azurerm_monitor_diagnostic_setting.kv_logs
    ]
}