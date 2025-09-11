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
