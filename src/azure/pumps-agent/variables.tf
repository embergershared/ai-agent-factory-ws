###############################################################################
# Variables – Manuals Storage
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
  default     = "manuals"
}

variable "folder_name" {
  description = "Virtual folder path inside the container for PDF files."
  type        = string
  default     = "pdfs"
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
