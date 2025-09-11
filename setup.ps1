# Fetch all public keys from GitHub and save to a file
$githubUsername = "cdorsman"
$keysUrl = "https://github.com/$githubUsername.keys"
$publicKeys = Invoke-WebRequest -Uri $keysUrl -UseBasicParsing
$publicKeyFile = "$env:USERPROFILE\.ssh\github_id.pub"

# Save all keys to the file (one per line)
$publicKeys.Content | Set-Content -Path $publicKeyFile
Write-Host "All public keys saved to $publicKeyFile"

# Create module folders
$folders = @(
    "modules/resource_group",
    "modules/network",
    "modules/nsg",
    "modules/vmss",
    "modules/autoscale"
)

foreach ($folder in $folders) {
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
}

# --- Root main.tf ---
@'
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "rg" {
  source   = "./modules/resource_group"
  providers = { azurerm = azurerm }
  rg_name  = var.rg_name
  location = var.location
}

module "network" {
  source        = "./modules/network"
  providers = { azurerm = azurerm }
  rg_name       = module.rg.name
  location      = module.rg.location
  vnet_name     = var.vnet_name
  address_space = var.vnet_address_space
  subnets       = var.subnets
}

module "nsg_web" {
  source    = "./modules/nsg"
  providers = { azurerm = azurerm }
  rg_name   = module.rg.name
  location  = module.rg.location
  nsg_name  = "WebSubnetNSG"
  rules     = var.web_nsg_rules
  subnet_id = module.network.subnet_ids["web"]
}

module "nsg_db" {
  source    = "./modules/nsg"
  providers = { azurerm = azurerm }
  rg_name   = module.rg.name
  location  = module.rg.location
  nsg_name  = "DBSubnetNSG"
  rules     = var.db_nsg_rules
  subnet_id = module.network.subnet_ids["db"]
}

module "vmss" {
  source         = "./modules/vmss"
  providers = { azurerm = azurerm }
  rg_name        = module.rg.name
  location       = module.rg.location
  subnet_id      = module.network.subnet_ids["web"]
  admin_username = var.admin_username
  ssh_keys_file  = var.ssh_keys_file
}

module "autoscale" {
  source             = "./modules/autoscale"
  providers = { azurerm = azurerm }
  rg_name            = module.rg.name
  location           = module.rg.location
  target_resource_id = module.vmss.vmss_id
}
'@ | Set-Content -Path "main.tf"

# --- Root variables.tf ---
@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "vnet_name" {
  type = string
}
variable "vnet_address_space" {
  type = list(string)
}
variable "subnets" {
  type = map(list(string))
}
variable "web_nsg_rules" {
  type = list(any)
}
variable "db_nsg_rules" {
  type = list(any)
}
variable "admin_username" {
  type = string
}
variable "ssh_keys_file" {
  type = string
}
'@ | Set-Content -Path "variables.tf"

# --- Root terraform.tfvars ---
@"
ssh_keys_file = `"$publicKeyFile`"
"@ | Set-Content -Path "terraform.tfvars"

# --- cloud-init.tpl ---
@'
#cloud-config
users:
  - name: ${admin_username}
    ssh-authorized-keys:
%{ for key in keys ~}
      - ${key}
%{ endfor }
'@ | Set-Content -Path "cloud-init.tpl"

# --- modules/resource_group/main.tf ---
@'
provider "azurerm" {}

resource "azurerm_resource_group" "this" {
  name     = var.rg_name
  location = var.location
}

output "name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}
'@ | Set-Content -Path "modules/resource_group/main.tf"

@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
'@ | Set-Content -Path "modules/resource_group/variables.tf"

# --- modules/network/main.tf ---
@'
provider "azurerm" {}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}
'@ | Set-Content -Path "modules/network/main.tf"

@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "vnet_name" {
  type = string
}
variable "address_space" {
  type = list(string)
}
variable "subnets" {
  type = map(list(string))
}
'@ | Set-Content -Path "modules/network/variables.tf"

# --- modules/nsg/main.tf ---
@'
provider "azurerm" {}

resource "azurerm_network_security_group" "this" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.rg_name

  dynamic "security_rule" {
    for_each = var.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
'@ | Set-Content -Path "modules/nsg/main.tf"

@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "nsg_name" {
  type = string
}
variable "rules" {
  type = list(any)
}
variable "subnet_id" {
  type = string
}
'@ | Set-Content -Path "modules/nsg/variables.tf"

# --- modules/vmss/main.tf ---
@'
provider "azurerm" {}

locals {
  ssh_keys = split("\n", file(var.ssh_keys_file))
  cloud_init = templatefile("${path.root}/cloud-init.tpl", {
    admin_username = var.admin_username
    keys           = local.ssh_keys
  })
}

resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = "vmss"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = var.admin_username

  # Remove admin_ssh_key block; cloud-init handles authorized_keys

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
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
'@ | Set-Content -Path "modules/vmss/main.tf"

@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "admin_username" {
  type = string
}
variable "ssh_keys_file" {
  type = string
}
'@ | Set-Content -Path "modules/vmss/variables.tf"

# --- modules/autoscale/main.tf ---
@'
provider "azurerm" {}

resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "autoscale"
  location            = var.location
  resource_group_name = var.rg_name
  target_resource_id  = var.target_resource_id

  profile {
    name = "defaultProfile"
    capacity {
      minimum = "1"
      maximum = "5"
      default = "2"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.target_resource_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = var.target_resource_id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}
'@ | Set-Content -Path "modules/autoscale/main.tf"

@'
variable "rg_name" {
  type = string
}
variable "location" {
  type = string
}
variable "target_resource_id" {
  type = string
}
'@ | Set-Content -Path "modules/autoscale/variables.tf"

Write-Host "Terraform project structure and files created successfully."
Write-Host "All GitHub SSH public keys for $githubUsername added to $publicKeyFile and will be injected into VMSS authorized_keys via cloud-init."