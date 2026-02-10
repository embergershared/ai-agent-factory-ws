###############################################################################
# Module: Azure AI Search
###############################################################################

resource "azurerm_search_service" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Use managed identity for data-plane auth
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
