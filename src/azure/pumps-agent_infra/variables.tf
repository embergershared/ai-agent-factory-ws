###############################################################################
# Variables - Manuals Storage
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
variable "base_infra_project_name" {
  description = "Project name used in the base_infra deployment (to derive its resource group name)."
  type        = string
}

variable "base_infra_environment" {
  description = "Environment used in the base_infra deployment. Defaults to the same environment as this deployment."
  type        = string
}

variable "base_infra_sequence_number" {
  description = "Sequence number used in the base_infra deployment. Defaults to the same sequence as this deployment."
  type        = string
}

# ─── Naming & Environment ───────────────────────────────────────────────────
variable "project_name" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "pumps-manuals"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,25}$", var.project_name))
    error_message = "project_name must be 2-25 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, prod, or demo."
  type        = string
  default     = "demo"

  validation {
    condition     = contains(["dev", "staging", "prod", "demo"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, demo."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "swedencentral"
}

variable "sequence_number" {
  description = "Sequence number appended to resource names (e.g. '01')."
  type        = string
  default     = "01"
}

# ─── Tags ────────────────────────────────────────────────────────────────────
variable "extra_tags" {
  description = "Additional tags to merge with defaults."
  type        = map(string)
  default     = {}
}

# ─── Storage Account ────────────────────────────────────────────────────────
variable "storage_account_tier" {
  description = "Performance tier for the storage account."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type for the storage account."
  type        = string
  default     = "LRS"
}

# ─── Container & Folder ─────────────────────────────────────────────────────
variable "container_name" {
  description = "Name of the blob container for storing manuals."
  type        = string
  default     = "pumps-manuals"
}

# ─── AI Foundry Project ─────────────────────────────────────────────────────
variable "base_infra_foundry_cognitive_account_name" {
  description = "Name of the Foundry resource created in the base_infra deployment."
  type        = string
}
variable "pump_foundry_project_name" {
  description = "Project name for the Pump Foundry."
  type        = string
  default     = "demo-v2-project"
}
variable "pump_foundry_project_description" {
  description = "Project description for the Pump Foundry."
  type        = string
  default     = "Demo project in Foundry v2"
}

# ─── Container App (MCP Pump Switch) ─────────────────────────────────────────
variable "base_infra_aca_env_name" {
  description = "Name of the Container Apps Environment from base_infra."
  type        = string
}

variable "base_infra_acr_name" {
  description = "Name of the Azure Container Registry from base_infra."
  type        = string
}

variable "base_infra_ai_search_name" {
  description = "Name of the Azure AI Search service from base_infra."
  type        = string
}

variable "base_infra_cognitive_services_name" {
  description = "Name of the Cognitive Services (multi-service) account from base_infra."
  type        = string
}

variable "base_infra_openai_name" {
  description = "Name of the Azure OpenAI account from base_infra."
  type        = string
}

# ─── Search Index Settings ───────────────────────────────────────────────────
variable "search_index_prefix" {
  description = "Name prefix for all Search index resources (datasource, index, skillset, indexer, knowledge source, knowledge base)."
  type        = string
  default     = "multimodal-rag-test"
}

variable "search_index_api_version" {
  description = "Azure Search REST API version for index operations."
  type        = string
  default     = "2025-05-01-preview"
}

variable "search_knowledge_api_version" {
  description = "Azure Search REST API version for knowledge source/base operations."
  type        = string
  default     = "2025-11-01-preview"
}

variable "search_kb_chat_deployment" {
  description = "Azure OpenAI chat deployment name used by the knowledge base."
  type        = string
  default     = "gpt-4.1"
}

variable "search_kb_chat_model" {
  description = "Azure OpenAI chat model name used by the knowledge base."
  type        = string
  default     = "gpt-4.1"
}

variable "mcp_app_name" {
  description = "Short name for the MCP app, used to build resource names."
  type        = string
  default     = "mcp-pump-switch"
}

variable "mcp_container_image" {
  description = "Full container image reference (registry/repo:tag)."
  type        = string
  default     = "acrswcs3aifoundryv2demo012uc24.azurecr.io/mcp-pump-switch:latest"
}

variable "mcp_container_cpu" {
  description = "CPU cores for the MCP container."
  type        = number
  default     = 0.5
}

variable "mcp_container_memory" {
  description = "Memory (in Gi) for the MCP container."
  type        = string
  default     = "1Gi"
}

variable "mcp_api_key" {
  description = "API key for the MCP server endpoint."
  type        = string
  sensitive   = true
  default     = "dev-secret"
}
