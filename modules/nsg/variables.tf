variable "rg_name" {}
variable "location" {}
variable "nsg_name" {}
variable "rules" { type = list(any) }
variable "subnet_id" {}
