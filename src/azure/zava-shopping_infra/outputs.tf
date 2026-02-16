###############################################################################
# Outputs - Zava Shopping Multi-Agent
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

# ─── Container App ──────────────────────────────────────────────────────────
output "zava_shopping_fqdn" {
  description = "Public FQDN of the Zava Shopping Multi-Agent container app."
  value       = azurerm_container_app.zava_shopping.ingress[0].fqdn
}

output "zava_shopping_url" {
  description = "Public HTTPS URL of the Zava Shopping Multi-Agent container app."
  value       = "https://${azurerm_container_app.zava_shopping.ingress[0].fqdn}"
}

# ─── Container Registry ────────────────────────────────────────────────────
output "acr_login_server" {
  description = "ACR login server used for the container image."
  value       = data.azurerm_container_registry.base.login_server
}

output "container_image" {
  description = "Full container image reference deployed."
  value       = local.zava_container_image
}
