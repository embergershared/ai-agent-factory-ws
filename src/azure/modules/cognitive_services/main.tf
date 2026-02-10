###############################################################################
# Module: Cognitive Services (Multi-Service Account)
###############################################################################

resource "azurerm_cognitive_account" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "CognitiveServices"
  sku_name            = var.sku

  custom_subdomain_name = var.name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
