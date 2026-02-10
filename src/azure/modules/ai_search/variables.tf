###############################################################################
# Module: Azure AI Search
###############################################################################

variable "name" {
  description = "Name of the Azure AI Search service."
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
  description = "SKU for Azure AI Search."
  type        = string
  default     = "basic"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
