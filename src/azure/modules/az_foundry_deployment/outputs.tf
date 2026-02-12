###############################################################################
# Module: Azure Foundry Deployment - Outputs
###############################################################################

output "id" {
  description = "The resource ID of the Foundry deployment."
  value       = azurerm_cognitive_deployment.this.id
}

output "name" {
  description = "The name of the Foundry deployment."
  value       = azurerm_cognitive_deployment.this.name
}
