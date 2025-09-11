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
  default = "/tmp/id_rsa.pub"
}
