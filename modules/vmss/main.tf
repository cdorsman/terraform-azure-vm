resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "vmss"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = var.admin_username

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/tmp/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = var.subnet_id
      primary   = true
    }
  }

  custom_data = base64encode(local.cloud_init)
}

output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.this.id
}
