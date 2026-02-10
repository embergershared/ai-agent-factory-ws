###############################################################################
# Module: Key Vault
###############################################################################

resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = var.sku_name

  # Use RBAC for access control (no access policies needed)
  access_policy = []

  # Security defaults
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [access_policy]
  }
}
