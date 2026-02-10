###############################################################################
# Outputs – Manuals Storage
###############################################################################

output "resource_group_name" {
  description = "Name of the resource group (from base_infra)."
  value       = data.azurerm_resource_group.base.name
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = module.storage_account.id
}

output "storage_account_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = module.storage_account.primary_blob_endpoint
}

output "container_name" {
  description = "Name of the manuals blob container."
  value       = module.manuals_container.name
}

output "folder_path" {
  description = "Virtual folder path inside the container."
  value       = "${var.folder_name}/"
}
