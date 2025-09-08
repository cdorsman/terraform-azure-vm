variable "rg_name" {}
variable "location" {}
variable "vnet_name" {}
variable "vnet_address_space" { type = list(string) }
variable "subnets" { type = map(list(string)) }
variable "web_nsg_rules" { type = list(any) }
variable "db_nsg_rules" { type = list(any) }
variable "admin_username" {}
variable "ssh_key_path" {}
