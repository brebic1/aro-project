resource "azurerm_network_interface" "jump_nic" {
    name = "jump-nic"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
    name = "jump-ip-config"
    subnet_id = azurerm_subnet.jump_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.jump_pip.id
}
    tags = local.tags
}


resource "azurerm_windows_virtual_machine" "jump" {
    name = "jump-vm"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.jump_nic.id]
    size = "Standard_B1s"
    admin_username = "azureuser"
    admin_password = "Str0ng!Password123"
    
    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2016-datacenter"
        version = "latest"
    }

    identity {
        type = "SystemAssigned"
    }

    lifecycle {
        ignore_changes = [size]
    }
    
    patch_mode = "AutomaticByPlatform"
    tags = local.tags
}

