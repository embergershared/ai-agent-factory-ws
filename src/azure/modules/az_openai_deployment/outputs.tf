###############################################################################
# Module: Azure OpenAI Deployment - Outputs
###############################################################################

output "id" {
  description = "The resource ID of the OpenAI deployment."
  value       = azurerm_cognitive_deployment.this.id
}

output "name" {
  description = "The name of the OpenAI deployment."
  value       = azurerm_cognitive_deployment.this.name
}
