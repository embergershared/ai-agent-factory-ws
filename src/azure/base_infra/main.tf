###############################################################################
# Root Main - Module Orchestration
#
# This file wires together all child modules into a single deployment.
# Each module lives under ../modules/<name>/ and receives its inputs from
# the centralized locals and root variables.
###############################################################################


# ═══════════════════════════════════════════════════════════════════════════════
# 0. Internals
# ═══════════════════════════════════════════════════════════════════════════════
resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
  numeric = true
}

# Captured once at creation, stored in state, never changes on subsequent runs
resource "time_static" "created" {}


# ═══════════════════════════════════════════════════════════════════════════════
# 1. Resource Group
# ═══════════════════════════════════════════════════════════════════════════════
module "resource_group" {
  source = "../modules/resource_group"

  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}


# ═══════════════════════════════════════════════════════════════════════════════
# 2. Virtual Network & Subnets
# ═══════════════════════════════════════════════════════════════════════════════
module "vnet" {
  source = "../modules/vnet"

  name                = local.vnet_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.vnet_address_space
  subnets             = local.subnets
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2b. Network Security Groups (one per subnet)
# ═══════════════════════════════════════════════════════════════════════════════
module "nsg" {
  source = "../modules/nsg"

  nsg_name_prefix     = local.nsg_name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = module.vnet.subnet_ids
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Storage Account
# ═══════════════════════════════════════════════════════════════════════════════
module "storage_account" {
  source = "../modules/storage_account"

  name                = local.storage_account_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  account_tier        = var.storage_account_tier
  replication_type    = var.storage_replication_type
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. Key Vault
# ═══════════════════════════════════════════════════════════════════════════════
module "key_vault" {
  source = "../modules/key_vault"

  name                = local.key_vault_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = local.tenant_id
  sku_name            = var.key_vault_sku
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 5. Azure AI Search
# ═══════════════════════════════════════════════════════════════════════════════
module "ai_search" {
  source = "../modules/ai_search"

  name                = local.ai_search_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.ai_search_sku
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. Azure OpenAI
# ═══════════════════════════════════════════════════════════════════════════════
module "openai" {
  source = "../modules/openai"

  name                = local.openai_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.openai_sku
  model_deployments   = var.openai_model_deployments
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 7. Cognitive Services (Multi-Service Account)
# ═══════════════════════════════════════════════════════════════════════════════
module "cognitive_services" {
  source = "../modules/cognitive_services"

  name                = local.cognitive_services_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.cognitive_services_sku
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 8. Cosmos DB (NoSQL)
# ═══════════════════════════════════════════════════════════════════════════════
module "cosmosdb" {
  source = "../modules/cosmosdb"

  account_name        = local.cosmosdb_account_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  consistency_level   = var.cosmosdb_consistency_level
  enable_free_tier    = var.cosmosdb_enable_free_tier
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 9. Azure Container Registry
# ═══════════════════════════════════════════════════════════════════════════════
module "acr" {
  source = "../modules/acr"

  name                = local.acr_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 10. Azure Container Apps Environment
# ═══════════════════════════════════════════════════════════════════════════════
module "container_apps" {
  source = "../modules/container_apps"

  environment_name        = local.aca_env_name
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  log_analytics_name      = local.log_analytics_name
  log_analytics_retention = var.container_apps_log_analytics_retention
  subnet_id               = module.vnet.subnet_ids["aca"]
  tags                    = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 11. Application Insights (shared, needed by AI Foundry)
# ═══════════════════════════════════════════════════════════════════════════════
resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  application_type    = "web"
  workspace_id        = module.container_apps.log_analytics_workspace_id

  tags = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 12. Azure ML Workspace (azurerm_machine_learning_workspace)
# ═══════════════════════════════════════════════════════════════════════════════
module "ai_ml_workspace" {
  source = "../modules/ai_ml_workspace"

  hub_name                = local.ml_hub_name
  project_name            = local.ml_project_name
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  storage_account_id      = module.storage_account.id
  key_vault_id            = module.key_vault.id
  application_insights_id = azurerm_application_insights.this.id
  tags                    = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 13. Microsoft Foundry
# ═══════════════════════════════════════════════════════════════════════════════
module "ai_services" {
  source = "../modules/ai_new_foundry"

  name                = local.ai_services_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku_name            = var.foundry_sku
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 14. App Registration (Entra ID) for Bot Service
# ═══════════════════════════════════════════════════════════════════════════════
module "app_registration" {
  source = "../modules/app_registration"

  display_name = local.app_registration_name
  owners       = [local.object_id]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 15. Bot Service
# ═══════════════════════════════════════════════════════════════════════════════
module "bot_service" {
  source = "../modules/bot_service"

  name                    = local.bot_service_name
  resource_group_name     = module.resource_group.name
  sku                     = var.bot_service_sku
  display_name            = local.bot_service_display_name
  endpoint                = local.bot_service_endpoint
  microsoft_app_id        = module.app_registration.client_id
  microsoft_app_type      = var.bot_service_microsoft_app_type
  microsoft_app_tenant_id = local.tenant_id
  tags                    = local.common_tags
}


#*/
