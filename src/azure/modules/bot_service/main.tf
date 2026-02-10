###############################################################################
# Module: Azure Bot Service
###############################################################################

resource "azurerm_bot_service_azure_bot" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = "global"
  sku                 = var.sku
  microsoft_app_id    = var.microsoft_app_id

  display_name            = var.display_name
  endpoint                = var.endpoint
  microsoft_app_type      = var.microsoft_app_type
  microsoft_app_tenant_id = var.microsoft_app_tenant_id

  tags = var.tags
}
