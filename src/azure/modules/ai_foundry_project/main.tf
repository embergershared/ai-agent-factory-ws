###############################################################################
# Module: AI Foundry Project
#
# Deploys an AI Foundry Project as a child of an AI Services
# (Cognitive Services) account via azapi_resource.
#
# Resource type: microsoft.cognitiveservices/accounts/projects
#
# Reference:
#   https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/projects
###############################################################################

terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  name      = var.project_name
  parent_id = var.ai_services_account_id
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description = var.project_description
    }
  }

  tags = var.tags
}
