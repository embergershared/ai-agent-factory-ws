###############################################################################
# Module: Azure AI Foundry (AI Hub + AI Project)
###############################################################################

variable "hub_name" {
  description = "Name of the AI Hub."
  type        = string
}

variable "project_name" {
  description = "Name of the AI Project."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "storage_account_id" {
  description = "ID of the Storage Account to link to the AI Hub."
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to link to the AI Hub."
  type        = string
}

variable "application_insights_id" {
  description = "ID of the Application Insights instance to link to the AI Hub."
  type        = string
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
