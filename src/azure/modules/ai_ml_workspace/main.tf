###############################################################################
# Module: Azure ML Workspace (Hub + Project)
#
# Uses azurerm_machine_learning_workspace with kind = "Default".
###############################################################################

# ─── Application Insights (required by ML Workspace) ────────────────────────
# Provided via variable from root module

# ─── AI Hub (Machine Learning Workspace kind="Hub") ─────────────────────────
resource "azurerm_machine_learning_workspace" "hub" {
  name                = var.hub_name
  location            = var.location
  resource_group_name = var.resource_group_name

  kind = "Default" # ["Default" "FeatureStore"]

  storage_account_id      = var.storage_account_id
  key_vault_id            = var.key_vault_id
  application_insights_id = var.application_insights_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ─── AI Project ──────────────────────────────────────────────────────────────
resource "azurerm_machine_learning_workspace" "project" {
  name                = var.project_name
  location            = var.location
  resource_group_name = var.resource_group_name

  kind = "Default" # ["Default" "FeatureStore"]

  # Project still requires these even when linked to a hub
  storage_account_id      = var.storage_account_id
  key_vault_id            = var.key_vault_id
  application_insights_id = var.application_insights_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [azurerm_machine_learning_workspace.hub]
}
