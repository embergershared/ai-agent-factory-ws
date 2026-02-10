###############################################################################
# Module: Azure OpenAI
###############################################################################

variable "name" {
  description = "Name of the Azure OpenAI account."
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
  description = "SKU for Azure OpenAI."
  type        = string
  default     = "S0"
}

variable "model_deployments" {
  description = "Map of model deployments."
  type = map(object({
    model_name     = string
    model_version  = string
    model_format   = optional(string, "OpenAI")
    scale_type     = optional(string, "GlobalStandard")
    scale_capacity = optional(number, 1)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
