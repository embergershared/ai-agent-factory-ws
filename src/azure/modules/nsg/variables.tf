###############################################################################
# Module: Network Security Groups
###############################################################################

variable "nsg_name_prefix" {
  description = "Name prefix for the NSGs (e.g. 'nsg-myproject-dev-01')."
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

variable "subnet_ids" {
  description = "Map of subnet name → subnet ID. One NSG is created per entry."
  type        = map(string)
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
