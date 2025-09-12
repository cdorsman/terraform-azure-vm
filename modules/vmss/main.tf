resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "vmss"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = var.admin_username

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
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
}

output "vmss_id" {
  value = azurerm_linux_virtual_machine_scale_set.this.id
}
