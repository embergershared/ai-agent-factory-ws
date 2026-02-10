output "hub_id" {
  description = "ID of the AI Hub."
  value       = azurerm_machine_learning_workspace.hub.id
}

output "hub_name" {
  description = "Name of the AI Hub."
  value       = azurerm_machine_learning_workspace.hub.name
}

output "project_id" {
  description = "ID of the AI Project."
  value       = azurerm_machine_learning_workspace.project.id
}

output "project_name" {
  description = "Name of the AI Project."
  value       = azurerm_machine_learning_workspace.project.name
}

output "hub_identity_principal_id" {
  description = "Principal ID of the AI Hub system-assigned managed identity."
  value       = azurerm_machine_learning_workspace.hub.identity[0].principal_id
}

output "project_identity_principal_id" {
  description = "Principal ID of the AI Project system-assigned managed identity."
  value       = azurerm_machine_learning_workspace.project.identity[0].principal_id
}
