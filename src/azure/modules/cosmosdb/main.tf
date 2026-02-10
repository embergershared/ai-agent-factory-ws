###############################################################################
# Module: Azure Cosmos DB (NoSQL API)
#
# Best Practices applied:
#   - Session consistency (configurable) for balanced latency/consistency
#   - System-assigned managed identity
#   - Automatic failover enabled
#   - Free tier toggle (one per subscription)
###############################################################################

resource "azurerm_cosmosdb_account" "this" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # NoSQL API

  free_tier_enabled          = var.enable_free_tier
  automatic_failover_enabled = true

  consistency_policy {
    consistency_level = var.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
