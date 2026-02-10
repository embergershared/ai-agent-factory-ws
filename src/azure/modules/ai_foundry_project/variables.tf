###############################################################################
# Module: AI Foundry Project
###############################################################################

variable "project_name" {
  description = "Name of the AI Foundry project"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,33}$", var.project_name))
    error_message = "project_name must be between 3 and 33 characters, and may only include alphanumeric characters and '-'."
  }
}

variable "project_description" {
  description = "Description of the AI Foundry project"
  type        = string
  default     = ""
}

variable "ai_services_account_id" {
  description = "Resource ID of the AI Services account"
  type        = string
}

variable "location" {
  description = "Azure region for the project"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the project"
  type        = map(string)
  default     = {}
}
