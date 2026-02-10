###############################################################################
# Module: Azure Bot Service - Variables
###############################################################################

variable "name" {
  description = "Name of the Azure Bot Service."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku" {
  description = "SKU for the Bot Service (F0 for free, S1 for standard)."
  type        = string
  default     = "S1"
}

variable "microsoft_app_id" {
  description = "Microsoft App ID (Azure AD application registration) for the bot."
  type        = string
}

variable "microsoft_app_type" {
  description = "Microsoft App Type: SingleTenant, MultiTenant, or UserAssignedMSI."
  type        = string
  default     = "SingleTenant"

  validation {
    condition     = contains(["SingleTenant", "UserAssignedMSI"], var.microsoft_app_type)
    error_message = "microsoft_app_type must be one of: SingleTenant, UserAssignedMSI."
  }
}

variable "display_name" {
  description = "Display name for the Bot Service."
  type        = string
}

variable "endpoint" {
  description = "The bot messaging endpoint URL (e.g. AI Foundry project activity protocol URL)."
  type        = string
  default     = ""
}

variable "microsoft_app_tenant_id" {
  description = "Tenant ID for the Microsoft App (required for SingleTenant)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
