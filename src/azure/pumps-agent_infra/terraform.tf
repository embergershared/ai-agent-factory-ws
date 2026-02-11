###############################################################################
# Terraform & Provider Configuration - Manuals Storage
###############################################################################

terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # Uncomment and configure for remote state
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "tfstatestore"
  #   container_name       = "tfstate"
  #   key                  = "manuals-storage.tfstate"
  # }
}
