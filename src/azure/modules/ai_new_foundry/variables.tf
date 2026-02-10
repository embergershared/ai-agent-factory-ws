###############################################################################
# Module: Azure AI Services (Cognitive Account – kind = "AIServices")
###############################################################################

variable "name" {
  description = "Name of the AI Services account."
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

variable "sku_name" {
  description = "SKU for the AI Services account (e.g. S0, S1, F0)."
  type        = string
  default     = "S0"
}

variable "custom_subdomain_name" {
  description = "Custom subdomain for the Cognitive Account endpoint. Defaults to the resource name."
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled."
  type        = bool
  default     = true
}

variable "local_auth_enabled" {
  description = "Whether local (key-based) authentication is enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
