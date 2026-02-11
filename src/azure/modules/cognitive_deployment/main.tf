###############################################################################
# Module: Cognitive Deployment (Model Deployment)
#
# Deploys a model (e.g. OpenAI GPT, embedding) to a Cognitive Services /
# AI Services / AI Foundry account using azurerm_cognitive_deployment.
#
# Reference: https://github.com/microsoft-foundry/foundry-samples/tree/main/
#            infrastructure/infrastructure-setup-terraform/00-basic-azurerm/code
###############################################################################

resource "azurerm_cognitive_deployment" "this" {
  name                 = var.name
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
