###############################################################################
# Module: Storage Account
###############################################################################

variable "name" {
  description = "Name of the storage account (must be globally unique, lowercase, no hyphens)."
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

variable "account_tier" {
  description = "Performance tier."
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
