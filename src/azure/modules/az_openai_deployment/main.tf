###############################################################################
# Module: Azure OpenAI Deployment
#
# Deploys an OpenAI model (e.g. GPT, embedding) to a Cognitive Services /
# AI Services account using azurerm_cognitive_deployment.
#
# This is a thin wrapper around azurerm_cognitive_deployment with OpenAI-
# specific defaults (model_format = "OpenAI", sku_name = "Standard").
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
