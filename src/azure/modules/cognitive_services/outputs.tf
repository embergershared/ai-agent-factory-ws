output "id" {
  description = "ID of the Cognitive Services account."
  value       = azurerm_cognitive_account.this.id
}

output "name" {
  description = "Name of the Cognitive Services account."
  value       = azurerm_cognitive_account.this.name
}

output "endpoint" {
  description = "Endpoint of the Cognitive Services account."
  value       = azurerm_cognitive_account.this.endpoint
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_cognitive_account.this.identity[0].principal_id
}
