###############################################################################
# Module: Key Vault
###############################################################################

variable "name" {
  description = "Name of the Key Vault."
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

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

variable "sku_name" {
  description = "SKU for Key Vault."
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
