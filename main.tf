module "rg" {
  source   = "./modules/resource_group"
  rg_name  = var.rg_name
  location = var.location
}

module "network" {
  source        = "./modules/network"
  rg_name       = module.rg.name
  location      = module.rg.location
  vnet_name     = var.vnet_name
  address_space = var.vnet_address_space
  subnets       = var.subnets
}

module "nsg_web" {
  source    = "./modules/nsg"
  rg_name   = module.rg.name
  location  = module.rg.location
  nsg_name  = "WebSubnetNSG"
  rules     = var.web_nsg_rules
  subnet_id = module.network.subnet_ids["web"]
}

module "nsg_db" {
  source    = "./modules/nsg"
  rg_name   = module.rg.name
  location  = module.rg.location
  nsg_name  = "DBSubnetNSG"
  rules     = var.db_nsg_rules
  subnet_id = module.network.subnet_ids["db"]
}

module "vmss" {
  source         = "./modules/vmss"
  rg_name        = module.rg.name
  location       = module.rg.location
  subnet_id      = module.network.subnet_ids["web"]
  admin_username = var.admin_username
  ssh_key_path   = var.ssh_key_path
}

module "autoscale" {
  source             = "./modules/autoscale"
  rg_name            = module.rg.name
  location           = module.rg.location
  target_resource_id = module.vmss.vmss_id
}
