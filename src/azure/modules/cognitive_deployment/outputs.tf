###############################################################################
# Module: Cognitive Deployment - Outputs
###############################################################################

output "id" {
  description = "The ID of the cognitive deployment."
  value       = azurerm_cognitive_deployment.this.id
}

output "name" {
  description = "The name of the cognitive deployment."
  value       = azurerm_cognitive_deployment.this.name
}
