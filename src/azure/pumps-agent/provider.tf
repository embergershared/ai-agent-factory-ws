###############################################################################
# Provider Configuration – Manuals Storage
###############################################################################

provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  resource_provider_registrations = "none"
  storage_use_azuread             = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
