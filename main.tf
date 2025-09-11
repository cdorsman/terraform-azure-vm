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
