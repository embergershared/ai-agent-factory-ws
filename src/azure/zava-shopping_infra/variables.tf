###############################################################################
# Variables - Zava Shopping Multi-Agent
###############################################################################

# ─── Subscription & Identity ────────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure Subscription ID to deploy into."
  type        = string
}
variable "tenant_id" {
  description = "Azure Tenant ID."
  type        = string
}
variable "client_id" {
  description = "Service Principal Client ID."
  type        = string
}
variable "client_secret" {
  description = "Service Principal Client Secret."
  type        = string
  sensitive   = true
}

# ─── Base Infrastructure Reference ──────────────────────────────────────────
variable "base_infra_rg_name" {
  description = "Name of the resource group where the base infrastructure is deployed."
  type        = string
}

# ─── Container App (Zava Shopping Multi-Agent) ───────────────────────────────
variable "zava_app_name" {
  description = "Short name for the Zava Shopping app, used to build resource names."
  type        = string
  default     = "zava-shopping-multi"
}

variable "zava_container_cpu" {
  description = "CPU cores for the Zava Shopping container."
  type        = number
  default     = 1.0
}

variable "zava_container_memory" {
  description = "Memory (in Gi) for the Zava Shopping container."
  type        = string
  default     = "2Gi"
}

variable "zava_container_min_replicas" {
  description = "Minimum number of replicas for the Zava Shopping container."
  type        = number
  default     = 0
}

variable "zava_container_max_replicas" {
  description = "Maximum number of replicas for the Zava Shopping container."
  type        = number
  default     = 1
}

# ─── Foundry AI Services (the account the app connects to) ──────────────────
variable "foundry_ai_services_name" {
  description = "Name of the AI Services (Foundry) account used by the app (may differ from base infra)."
  type        = string
}

variable "foundry_ai_services_rg_name" {
  description = "Resource group containing the Foundry AI Services account. Defaults to base_infra_rg_name."
  type        = string
  default     = ""
}

# ─── App Environment Variables ───────────────────────────────────────────────

variable "foundry_endpoint" {
  description = "FOUNDRY_ENDPOINT for AI Project Client."
  type        = string
}

variable "foundry_key" {
  description = "FOUNDRY_KEY for AI Project Client."
  type        = string
  sensitive   = true
}

variable "foundry_api_version" {
  description = "FOUNDRY_API_VERSION."
  type        = string
  default     = "2025-01-01-preview"
}

variable "gpt_endpoint" {
  description = "GPT endpoint URL."
  type        = string
}

variable "gpt_deployment" {
  description = "GPT deployment name."
  type        = string
  default     = "gpt-5-mini"
}

variable "gpt_api_key" {
  description = "GPT API key."
  type        = string
  sensitive   = true
}

variable "gpt_api_version" {
  description = "GPT API version."
  type        = string
  default     = "2025-01-01-preview"
}

variable "phi_4_endpoint" {
  description = "Phi-4 model endpoint URL."
  type        = string
}

variable "phi_4_deployment" {
  description = "Phi-4 deployment name."
  type        = string
  default     = "Phi-4"
}

variable "phi_4_api_key" {
  description = "Phi-4 API key."
  type        = string
  sensitive   = true
}

variable "phi_4_api_version" {
  description = "Phi-4 API version."
  type        = string
  default     = "2024-05-01-preview"
}

variable "embedding_endpoint" {
  description = "Text embedding endpoint URL."
  type        = string
}

variable "embedding_deployment" {
  description = "Text embedding deployment name."
  type        = string
  default     = "text-embedding-3-large"
}

variable "embedding_api_key" {
  description = "Text embedding API key."
  type        = string
  sensitive   = true
}

variable "embedding_api_version" {
  description = "Text embedding API version."
  type        = string
  default     = "2025-01-01-preview"
}

variable "gpt_image_1_endpoint" {
  description = "GPT image generation endpoint URL."
  type        = string
}

variable "gpt_image_1_deployment" {
  description = "GPT image generation deployment name."
  type        = string
  default     = "gpt-image-1"
}

variable "gpt_image_1_api_version" {
  description = "GPT image generation API version."
  type        = string
  default     = "2025-01-01-preview"
}

variable "subscription_key" {
  description = "Subscription key for image generation."
  type        = string
  sensitive   = true
}

variable "blob_connection_string" {
  description = "Azure Blob Storage connection string."
  type        = string
  sensitive   = true
}

variable "storage_account_name" {
  description = "Storage account name."
  type        = string
}

variable "storage_container_name" {
  description = "Storage container name."
  type        = string
  default     = "zava"
}

variable "cosmos_endpoint" {
  description = "Cosmos DB endpoint URL."
  type        = string
}

variable "cosmos_key" {
  description = "Cosmos DB access key."
  type        = string
  sensitive   = true
}

variable "cosmos_database_name" {
  description = "Cosmos DB database name."
  type        = string
  default     = "zava"
}

variable "cosmos_container_name" {
  description = "Cosmos DB container name."
  type        = string
  default     = "product_catalog"
}

variable "appinsights_connection_string" {
  description = "Application Insights connection string."
  type        = string
  sensitive   = true
  default     = ""
}

variable "mcp_server_url" {
  description = "MCP Server URL (in-process, typically localhost)."
  type        = string
  default     = "http://localhost:8000/mcp-inventory/sse"
}

# ─── Agent IDs ───────────────────────────────────────────────────────────────
variable "agent_customer_loyalty" {
  description = "Agent ID for customer loyalty."
  type        = string
  default     = "customer-loyalty"
}

variable "agent_inventory" {
  description = "Agent ID for inventory."
  type        = string
  default     = "inventory-agent"
}

variable "agent_interior_designer" {
  description = "Agent ID for interior designer."
  type        = string
  default     = "interior-designer"
}

variable "agent_cora" {
  description = "Agent ID for Cora (general shopping assistant)."
  type        = string
  default     = "cora"
}

variable "agent_cart_manager" {
  description = "Agent ID for cart manager."
  type        = string
  default     = "cart-manager"
}

variable "agent_handoff_service" {
  description = "Agent ID for handoff service."
  type        = string
  default     = "handoff-service"
}
