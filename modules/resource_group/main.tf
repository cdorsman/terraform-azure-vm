provider "azurerm" {
  features {}
}

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
