###############################################################################
# Outputs – Manuals Storage
###############################################################################

output "resource_group_name" {
  description = "Name of the resource group (from base_infra)."
  value       = data.azurerm_resource_group.base.name
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = module.storage_account.id
}

output "storage_account_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = module.storage_account.primary_blob_endpoint
}

output "container_name" {
  description = "Name of the manuals blob container."
  value       = module.manuals_container.name
}


# ─── Container App ──────────────────────────────────────────────────────────
output "mcp_pump_switch_fqdn" {
  description = "Public FQDN of the MCP Pump Switch container app."
  value       = azurerm_container_app.mcp_pump_switch.ingress[0].fqdn
}

output "mcp_pump_switch_url" {
  description = "Public HTTPS URL of the MCP Pump Switch container app."
  value       = "https://${azurerm_container_app.mcp_pump_switch.ingress[0].fqdn}"
}
