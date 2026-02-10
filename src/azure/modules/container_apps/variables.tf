###############################################################################
# Module: Azure Container Apps Environment
###############################################################################

variable "environment_name" {
  description = "Name of the Container Apps Environment."
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

variable "log_analytics_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

variable "log_analytics_retention" {
  description = "Retention in days for Log Analytics."
  type        = number
  default     = 30
}

variable "subnet_id" {
  description = "Subnet ID for the Container Apps Environment (optional)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}

variable "workload_profile_name" {
  description = "Name of the dedicated workload profile."
  type        = string
  default     = "dedicated-d4"
}

variable "workload_profile_type" {
  description = "Workload profile type (e.g., D4, D8, D16, D32, E4, E8, E16, E32)."
  type        = string
  default     = "D4"
}

variable "workload_profile_min_count" {
  description = "Minimum number of instances for the dedicated workload profile."
  type        = number
  default     = 0
}

variable "workload_profile_max_count" {
  description = "Maximum number of instances for the dedicated workload profile."
  type        = number
  default     = 1
}
