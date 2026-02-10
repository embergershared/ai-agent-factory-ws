output "id" {
  description = "ID of the Azure AI Search service."
  value       = azurerm_search_service.this.id
}

output "name" {
  description = "Name of the Azure AI Search service."
  value       = azurerm_search_service.this.name
}

output "endpoint" {
  description = "Endpoint URL of the Azure AI Search service."
  value       = "https://${azurerm_search_service.this.name}.search.windows.net"
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_search_service.this.identity[0].principal_id
}
