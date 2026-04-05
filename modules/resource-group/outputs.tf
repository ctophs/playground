output "name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "location" {
  description = "Location of the resource group."
  value       = azurerm_resource_group.this.location
}
