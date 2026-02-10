output "nsg_ids" {
  description = "Map of subnet name → NSG ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "nsg_names" {
  description = "Map of subnet name → NSG name."
  value       = { for k, v in azurerm_network_security_group.this : k => v.name }
}
