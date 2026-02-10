###############################################################################
# Root Variables
###############################################################################

# ─── Subscription & Identity ────────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure Subscription ID to deploy into."
  type        = string
}
variable "tenant_id" {}
variable "client_id" {}
variable "client_secret" {}


# ─── Naming & Environment ───────────────────────────────────────────────────
variable "project_name" {
  description = "Short project name used in resource naming (e.g. 'pumps')."
  type        = string
  default     = "pumps"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,25}$", var.project_name))
    error_message = "project_name must be 2-25 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod."
  type        = string
  default     = "dev"

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
  description = "A sequence number appended to resource names for uniqueness (e.g. '01')."
  type        = string
  default     = "01"
}

# ─── Tags ────────────────────────────────────────────────────────────────────
variable "extra_tags" {
  description = "Additional tags to merge with the default tags."
  type        = map(string)
  default     = {}
}

# ─── Networking ──────────────────────────────────────────────────────────────
variable "vnet_address_space" {
  description = "Address space for the virtual network."
  type        = string
  default     = "172.27.193.0/24"
}

variable "subnets" {
  description = <<-EOT
    Map of subnet definitions. Key = subnet name suffix.
    CIDRs are computed automatically from the VNet address space (as /27 slices).
    Only metadata (service endpoints, delegations, policies) needs to be specified.
  EOT
  type = map(object({
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, false)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }), null)
  }))
  default = {
    default = {}
    aca = {
      delegation = {
        name         = "aca-delegation"
        service_name = "Microsoft.App/environments"
        actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
    private-endpoints = {
      private_endpoint_network_policies = "Disabled"
    }
    ai = {
      service_endpoints = ["Microsoft.CognitiveServices", "Microsoft.Storage"]
    }
  }
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

# ─── Key Vault ───────────────────────────────────────────────────────────────
variable "key_vault_sku" {
  description = "SKU for Azure Key Vault."
  type        = string
  default     = "standard"
}

# ─── Azure AI Search ────────────────────────────────────────────────────────
variable "ai_search_sku" {
  description = "SKU for Azure AI Search."
  type        = string
  default     = "basic"
}

# ─── Azure OpenAI ────────────────────────────────────────────────────────────
variable "openai_sku" {
  description = "SKU for Azure OpenAI Cognitive Services."
  type        = string
  default     = "S0"
}

variable "openai_model_deployments" {
  description = "Map of OpenAI model deployments."
  type = map(object({
    model_name     = string
    model_version  = string
    model_format   = optional(string, "OpenAI")
    scale_type     = optional(string, "GlobalStandard")
    scale_capacity = optional(number, 1)
  }))
  default = {
    "gpt-4o" = {
      model_name    = "gpt-4o"
      model_version = "2024-11-20"
    }
  }
}

# ─── Cognitive Services ─────────────────────────────────────────────────────
variable "cognitive_services_sku" {
  description = "SKU for Cognitive Services multi-service account."
  type        = string
  default     = "S0"
}

# ─── Cosmos DB ───────────────────────────────────────────────────────────────
variable "cosmosdb_consistency_level" {
  description = "Default consistency level for Cosmos DB account."
  type        = string
  default     = "Session"
}

variable "cosmosdb_enable_free_tier" {
  description = "Enable Cosmos DB free tier (only one per subscription)."
  type        = bool
  default     = false
}

# ─── Container Registry ─────────────────────────────────────────────────────
variable "acr_sku" {
  description = "SKU for Azure Container Registry."
  type        = string
  default     = "Basic"
}

# ─── Container Apps ──────────────────────────────────────────────────────────
variable "container_apps_log_analytics_retention" {
  description = "Log Analytics workspace retention in days for Container Apps."
  type        = number
  default     = 30
}

# ─── AI Services ─────────────────────────────────────────────────────────────
variable "ai_services_sku" {
  description = "SKU for the AI Services account (Cognitive Account kind=AIServices)."
  type        = string
  default     = "S0"
}
variable "foundry_sku" {
  description = "SKU for the Foundry service."
  type        = string
  default     = "S0"
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

# ─── Bot Service ─────────────────────────────────────────────────────────────
variable "bot_service_sku" {
  description = "SKU for the Azure Bot Service (F0 or S1)."
  type        = string
  default     = "S1"
}
variable "bot_service_microsoft_app_type" {
  description = "Microsoft App Type: SingleTenant, MultiTenant, or UserAssignedMSI."
  type        = string
  default     = "SingleTenant"
}
variable "bot_service_agent_name" {
  description = "Name of the AI Foundry agent application (used in the bot endpoint URL)."
  type        = string
  default     = "pumps-agent"
}
