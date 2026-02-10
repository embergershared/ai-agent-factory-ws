output "id" {
  description = "ID of the Azure Container Registry."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "Name of the Azure Container Registry."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "Login server of the Azure Container Registry."
  value       = azurerm_container_registry.this.login_server
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_container_registry.this.identity[0].principal_id
}
