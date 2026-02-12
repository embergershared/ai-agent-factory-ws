###############################################################################
# Module: Azure Foundry Deployment
#
# Deploys a model (e.g. Phi-4, DeepSeek) to an AI Services / Foundry account
# using azurerm_cognitive_deployment.
#
# This is a thin wrapper around azurerm_cognitive_deployment with Foundry-
# specific defaults (model_format = "Microsoft", sku_name = "GlobalStandard").
###############################################################################

resource "azurerm_cognitive_deployment" "this" {
  name                 = var.deployment_name
  cognitive_account_id = var.cognitive_account_id

  model {
    format  = var.model_format
    name    = var.model_name
    version = var.model_version
  }

  sku {
    name     = var.sku_name
    capacity = var.sku_capacity
  }
}
