###############################################################################
# Outputs - Manuals Storage
###############################################################################

output "resource_group_name" {
  description = "Name of the resource group (from base_infra)."
  value       = data.azurerm_resource_group.base.name
}

output "location" {
  description = "Azure region of the resource group."
  value       = data.azurerm_resource_group.base.location
}

output "subscription_id" {
  description = "Azure Subscription ID."
  value       = var.subscription_id
}

output "manuals_storage_account_name" {
  description = "Name of the storage account."
  value       = module.manuals_storage_account.name
}

output "manuals_storage_account_id" {
  description = "Resource ID of the storage account."
  value       = module.manuals_storage_account.id
}

output "manuals_storage_account_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = module.manuals_storage_account.primary_blob_endpoint
}

output "container_name" {
  description = "Name of the manuals blob container."
  value       = module.manuals_container.name
}

# ─── AI Foundry ──────────────────────────────────────────────────────────────
output "foundry_resource_name" {
  description = "Name of the AI Foundry (AI Services) resource."
  value       = data.azurerm_cognitive_account.foundry.name
}

output "foundry_project_name" {
  description = "Name of the AI Foundry project."
  value       = var.pump_foundry_project_name
}

# ─── Azure AI Search ────────────────────────────────────────────────────────
output "search_name" {
  description = "Name of the Azure AI Search service."
  value       = data.azurerm_search_service.base.name
}

output "search_primary_key" {
  description = "Primary admin key of the Azure AI Search service."
  value       = data.azurerm_search_service.base.primary_key
  sensitive   = true
}

# ─── Azure OpenAI ────────────────────────────────────────────────────────────
output "aoai_endpoint" {
  description = "Azure OpenAI endpoint URL."
  value       = data.azurerm_cognitive_account.openai.endpoint
}

# ─── AI Services (Cognitive Services) ────────────────────────────────────────
output "ai_services_endpoint" {
  description = "AI Services (Cognitive Services) endpoint URL."
  value       = data.azurerm_cognitive_account.foundry.endpoint
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
