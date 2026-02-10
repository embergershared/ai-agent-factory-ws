###############################################################################
# Module: Storage Container
###############################################################################

variable "name" {
  description = "Name of the blob container."
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the parent storage account."
  type        = string
}

variable "container_access_type" {
  description = "Access level for the container (private, blob, or container)."
  type        = string
  default     = "private"
}
