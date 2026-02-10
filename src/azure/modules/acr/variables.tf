###############################################################################
# Module: Azure Container Registry
###############################################################################

variable "name" {
  description = "Name of the Azure Container Registry (globally unique, alphanumeric only)."
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

variable "sku" {
  description = "SKU for ACR."
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
