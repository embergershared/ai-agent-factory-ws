###############################################################################
# Module: Entra ID Application Registration - Outputs
###############################################################################

output "application_id" {
  description = "The Application (object) ID of the Entra ID application."
  value       = azuread_application.this.id
}

output "client_id" {
  description = "The Client ID (Application ID) of the Entra ID application."
  value       = azuread_application.this.client_id
}

output "display_name" {
  description = "The display name of the Entra ID application."
  value       = azuread_application.this.display_name
}

output "service_principal_id" {
  description = "The Object ID of the service principal."
  value       = azuread_service_principal.this.id
}

output "service_principal_object_id" {
  description = "The Object ID of the service principal."
  value       = azuread_service_principal.this.object_id
}
