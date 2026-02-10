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
