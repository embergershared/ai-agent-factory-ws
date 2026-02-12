###############################################################################
# Example variable values - copy to terraform.tfvars and fill in
###############################################################################

project_name    = "swc-s3-ai-msfoundry"
environment     = "demo"
location        = "swedencentral"
sequence_number = "02"

extra_tags = {
  CostCenter      = "US OGE"
  SecurityControl = "Ignore"
}

# Networking
vnet_address_space = "172.27.193.0/24"

# Storage
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

# Key Vault
key_vault_sku = "standard"

# AI Search
ai_search_sku = "basic"

# Azure OpenAI
openai_sku               = "S0"
openai_model_deployments = {}

# Cognitive Services
cognitive_services_sku = "S0"

# Cosmos DB
cosmosdb_consistency_level = "Session"
cosmosdb_enable_free_tier  = false

# Container Registry
acr_sku = "Basic"

# Container Apps
container_apps_log_analytics_retention = 30

# Foundry
foundry_sku = "S0"
