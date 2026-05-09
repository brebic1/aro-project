resource "null_resource" "deploy_func" {
    
    provisioner "local-exec" {
        command = "./deploy.ps1"
        interpreter = ["PowerShell", "-Command"]
        working_dir = "${path.module}/../func-app"

}
    depends_on = [ 
        azurerm_windows_function_app.functionapp     
        ]
}