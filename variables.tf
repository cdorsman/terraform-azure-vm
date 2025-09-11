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

variable "ssh_key_path" {
  description = "Path to the SSH public key"
  default     = file("/tmp/id_rsa.pub")
  type        = string
}