output "id" {
  description = "ID of the storage container."
  value       = azurerm_storage_container.this.id
}

output "name" {
  description = "Name of the storage container."
  value       = azurerm_storage_container.this.name
}
