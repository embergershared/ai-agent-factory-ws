###############################################################################
# Root Outputs
###############################################################################

# ─── Resource Group ──────────────────────────────────────────────────────────
output "resource_group_name" {
  description = "Name of the resource group."
  value       = module.resource_group.name
}
/*
output "resource_group_id" {
  description = "ID of the resource group."
  value       = module.resource_group.id
}

# ─── Virtual Network ────────────────────────────────────────────────────────
output "vnet_id" {
  description = "ID of the virtual network."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name → subnet ID."
  value       = module.vnet.subnet_ids
}

# ─── Storage Account ────────────────────────────────────────────────────────
output "storage_account_id" {
  description = "ID of the storage account."
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage_account.name
}

# ─── Key Vault ───────────────────────────────────────────────────────────────
output "key_vault_id" {
  description = "ID of the Key Vault."
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = module.key_vault.vault_uri
}

# ─── AI Search ───────────────────────────────────────────────────────────────
output "ai_search_id" {
  description = "ID of the Azure AI Search service."
  value       = module.ai_search.id
}

output "ai_search_endpoint" {
  description = "Endpoint of the Azure AI Search service."
  value       = module.ai_search.endpoint
}

# ─── Azure OpenAI ────────────────────────────────────────────────────────────
output "openai_id" {
  description = "ID of the Azure OpenAI account."
  value       = module.openai.id
}

output "openai_endpoint" {
  description = "Endpoint of the Azure OpenAI account."
  value       = module.openai.endpoint
}

# ─── Cognitive Services ─────────────────────────────────────────────────────
output "cognitive_services_id" {
  description = "ID of the Cognitive Services multi-account."
  value       = module.cognitive_services.id
}

output "cognitive_services_endpoint" {
  description = "Endpoint of the Cognitive Services multi-account."
  value       = module.cognitive_services.endpoint
}

# ─── Cosmos DB ───────────────────────────────────────────────────────────────
output "cosmosdb_account_id" {
  description = "ID of the Cosmos DB account."
  value       = module.cosmosdb.id
}

output "cosmosdb_endpoint" {
  description = "Endpoint of the Cosmos DB account."
  value       = module.cosmosdb.endpoint
}

# ─── Container Registry ─────────────────────────────────────────────────────
output "acr_id" {
  description = "ID of the Azure Container Registry."
  value       = module.acr.id
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = module.acr.login_server
}

# ─── Container Apps ──────────────────────────────────────────────────────────
output "aca_environment_id" {
  description = "ID of the Container Apps Environment."
  value       = module.container_apps.environment_id
}

# ─── AI ML Workspace ─────────────────────────────────────────────────────────
output "ml_hub_id" {
  description = "ID of the ML Workspace Hub."
  value       = module.ai_ml_workspace.hub_id
}

output "ml_project_id" {
  description = "ID of the ML Workspace Project."
  value       = module.ai_ml_workspace.project_id
}

# ─── AI Services ─────────────────────────────────────────────────────────────
output "ai_services_id" {
  description = "ID of the AI Services account."
  value       = module.ai_services.id
}

output "ai_services_endpoint" {
  description = "Endpoint of the AI Services account."
  value       = module.ai_services.endpoint
}

output "ai_foundry_project_id" {
  description = "ID of the AI Foundry project."
  value       = module.ai_services.project_id
}
#*/
