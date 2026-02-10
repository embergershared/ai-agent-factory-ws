###############################################################################
# Module: Azure AI Services (Cognitive Account – kind = "AIServices")
#
# Deploys an azurerm_cognitive_account with kind "AIServices".
# This is a multi-service Cognitive Services account that provides
# access to a broad set of Azure AI capabilities including:
#   - Azure OpenAI
#   - Speech, Vision, Language, etc.
#
# Reference:
#   https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account
###############################################################################

resource "azurerm_cognitive_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "AIServices"
  sku_name            = var.sku_name

  custom_subdomain_name = var.custom_subdomain_name != null ? var.custom_subdomain_name : var.name

  public_network_access_enabled = var.public_network_access_enabled
  local_auth_enabled            = var.local_auth_enabled
  project_management_enabled    = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
