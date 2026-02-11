###############################################################################
# Data Sources – Reference existing resources from base_infra
###############################################################################

data "azurerm_resource_group" "base" {
  name = local.base_infra_rg_name
}


data "azurerm_cognitive_account" "base" {
  name                = var.base_infra_foundry_cognitive_account_name
  resource_group_name = data.azurerm_resource_group.base.name
}

data "azurerm_container_app_environment" "base" {
  name                = var.base_infra_aca_env_name
  resource_group_name = data.azurerm_resource_group.base.name
}

data "azurerm_container_registry" "base" {
  name                = var.base_infra_acr_name
  resource_group_name = data.azurerm_resource_group.base.name
}

data "azurerm_search_service" "base" {
  name                = var.base_infra_ai_search_name
  resource_group_name = data.azurerm_resource_group.base.name
}

data "azurerm_cognitive_account" "cognitive" {
  name                = var.base_infra_cognitive_services_name
  resource_group_name = data.azurerm_resource_group.base.name
}

data "azurerm_cognitive_account" "openai" {
  name                = var.base_infra_openai_name
  resource_group_name = data.azurerm_resource_group.base.name
}
