variable "rg_name" {}
variable "location" {}
variable "vnet_name" {}
variable "address_space" { type = list(string) }
variable "subnets" { type = map(list(string)) }
