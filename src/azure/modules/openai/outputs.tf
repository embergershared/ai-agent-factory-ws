output "id" {
  description = "ID of the Azure OpenAI account."
  value       = azurerm_cognitive_account.this.id
}

output "name" {
  description = "Name of the Azure OpenAI account."
  value       = azurerm_cognitive_account.this.name
}

output "endpoint" {
  description = "Endpoint of the Azure OpenAI account."
  value       = azurerm_cognitive_account.this.endpoint
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_cognitive_account.this.identity[0].principal_id
}

output "deployment_ids" {
  description = "Map of deployment name → deployment ID."
  value       = { for k, v in azurerm_cognitive_deployment.this : k => v.id }
}
