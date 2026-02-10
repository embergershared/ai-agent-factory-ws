###############################################################################
# Module: Virtual Network
###############################################################################

variable "name" {
  description = "Name of the virtual network."
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

variable "address_space" {
  description = "Address space for the virtual network."
  type        = string
}

variable "subnets" {
  description = "Map of subnet definitions."
  type = map(object({
    address_prefix                                = string
    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, false)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }), null)
  }))
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}
