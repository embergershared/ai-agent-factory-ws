###############################################################################
# Module: Cognitive Services (Multi-Service Account)
###############################################################################

variable "name" {
  description = "Name of the Cognitive Services account."
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
  description = "SKU for Cognitive Services."
  type        = string
  default     = "S0"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
