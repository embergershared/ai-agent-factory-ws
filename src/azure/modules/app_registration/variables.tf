###############################################################################
# Module: Entra ID Application Registration - Variables
###############################################################################

variable "display_name" {
  description = "Display name for the Entra ID application registration."
  type        = string
}

variable "owners" {
  description = "List of object IDs of owners for the application and service principal."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the application and service principal."
  type        = list(string)
  default     = []
}
