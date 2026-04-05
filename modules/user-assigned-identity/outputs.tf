output "id" {
  description = "Resource ID of the user assigned identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Principal ID — used for role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID — used to configure SDK authentication."
  value       = azurerm_user_assigned_identity.this.client_id
}
