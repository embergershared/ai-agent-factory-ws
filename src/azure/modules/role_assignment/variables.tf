###############################################################################
# Module: Role Assignment - Variables
###############################################################################

variable "scope" {
  description = "The scope at which the role assignment applies (resource ID)."
  type        = string
}

variable "role_definition_name" {
  description = "The name of the built-in role to assign (e.g. 'Storage Blob Data Contributor')."
  type        = string
}

variable "principal_id" {
  description = "The principal (object) ID of the identity to assign the role to."
  type        = string
}
