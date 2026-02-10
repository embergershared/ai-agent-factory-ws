output "project_id" {
  description = "ID of the AI Foundry project."
  value       = azapi_resource.project.id
}

output "project_name" {
  description = "Name of the AI Foundry project."
  value       = azapi_resource.project.name
}

output "identity_principal_id" {
  description = "Principal ID of the project's system-assigned managed identity."
  value       = azapi_resource.project.identity[0].principal_id
}
