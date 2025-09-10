# prod.tfvars

# Resource group and region
rg_name  = "RG-MKB-Env"
location = "westus2"

# Networking
vnet_name          = "RG-MKB-Vnet"
vnet_address_space = ["10.10.0.0/16"]

subnets = {
  web = ["10.10.1.0/24"]
  app = ["10.10.2.0/24"]
  db  = ["10.10.3.0/24"]
}

# NSG rules
web_nsg_rules = [
  {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]

db_nsg_rules = [
  {
    name                       = "AllowMySQLFromAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_address_prefix      = "10.10.2.0/24"
    destination_port_range     = "3306"
    source_port_range          = "*"
    destination_address_prefix = "*"
  },
  {
    name                       = "DenyAllInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_address_prefix      = "*"
    destination_port_range     = "*"
    source_port_range          = "*"
    destination_address_prefix = "*"
  }
]

# Compute
admin_username = "azureuser"
admin_ssh_public_key = file(var.ssh_key_path)