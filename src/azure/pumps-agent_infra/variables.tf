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
variable "base_infra_rg_name" {
  description = "Name of the resource group where the base infrastructure is deployed."
  type        = string
}

# ─── Storage Account ────────────────────────────────────────────────────────
variable "storage_name_suffix" {
  description = "Short suffix appended to the storage account name (e.g. 'manuals')."
  type        = string
  default     = "manuals"

  validation {
    condition     = can(regex("^[a-z0-9]{1,10}$", var.storage_name_suffix))
    error_message = "storage_name_suffix must be 1-10 lowercase alphanumeric characters (no hyphens)."
  }
}

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
variable "mcp_app_name" {
  description = "Short name for the MCP app, used to build resource names."
  type        = string
  default     = "mcp-pump-switch"
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


