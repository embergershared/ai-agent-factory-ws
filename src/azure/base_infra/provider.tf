provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  resource_provider_registrations = "none" # Enum: core, none, all, extended, legacy
  storage_use_azuread             = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

provider "azapi" {
}

provider "azuread" {
  # To App registration creation = use of azsp module,
  # The following API Permissions must be added to the Terraform Service Principal:
  #   Application.ReadWrite.All + Grant admin consent
  #   When authenticated with a user principal, azuread_application requires one of the following directory roles: Application Administrator or Global Administrator
  #
  # More info here: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
}
