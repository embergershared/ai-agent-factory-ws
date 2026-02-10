###############################################################################
# Module: Azure Cosmos DB (NoSQL API)
###############################################################################

variable "account_name" {
  description = "Name of the Cosmos DB account."
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

variable "consistency_level" {
  description = "Default consistency level."
  type        = string
  default     = "Session"
}

variable "enable_free_tier" {
  description = "Enable free tier (one per subscription)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
