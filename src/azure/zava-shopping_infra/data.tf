###############################################################################
# Data Sources - Reference existing resources from base_infra
#
# Uses the same naming conventions as pumps-agent_infra.
# The RG name is parsed to derive all dependent resource names.
###############################################################################

# ─── Resource Group ──────────────────────────────────────────────────────────
data "azurerm_resource_group" "base" {
  name = var.base_infra_rg_name
}

# ─── Current client (SP) identity ─────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# ─── Derive base_infra naming parts from the RG name ────────────────────────
locals {
  # rg-<name_prefix>  →  strip the "rg-" prefix
  base_infra_name_prefix       = trimprefix(var.base_infra_rg_name, "rg-")
  base_infra_name_prefix_clean = replace(local.base_infra_name_prefix, "-", "")

  # ── Computed resource names (deterministic - no suffix) ──────────────────
  computed_aca_env_name = "aca-env-${local.base_infra_name_prefix}"
}

# ─── Discovery: ACR includes a random suffix we cannot predict ───────────────
data "azurerm_resources" "container_registries" {
  resource_group_name = data.azurerm_resource_group.base.name
  type                = "Microsoft.ContainerRegistry/registries"
}

locals {
  # Take the first (and expected only) ACR in the resource group
  discovered_acr_name = try(data.azurerm_resources.container_registries.resources[0].name, "")
}

# ─── Typed data sources (for full attribute access) ──────────────────────────

# Azure Container Registry
data "azurerm_container_registry" "base" {
  name                = local.discovered_acr_name
  resource_group_name = data.azurerm_resource_group.base.name
}

# Container Apps Environment
data "azurerm_container_app_environment" "base" {
  name                = local.computed_aca_env_name
  resource_group_name = data.azurerm_resource_group.base.name
}

# AI Services (Foundry) account - base infra (for ACR role etc.)
# Note: The app's actual Foundry AI Services account is defined below
# as data.azurerm_cognitive_account.app_foundry (may differ from base).

# ─── Foundry AI Services account that the app actually connects to ───────────
# This may live in the same or a different resource group from the base infra.
locals {
  foundry_rg_name = var.foundry_ai_services_rg_name != "" ? var.foundry_ai_services_rg_name : var.base_infra_rg_name
}

data "azurerm_cognitive_account" "app_foundry" {
  name                = var.foundry_ai_services_name
  resource_group_name = local.foundry_rg_name
}

# ─── Validation: fail early if a required resource is missing ────────────────
resource "terraform_data" "validate_base_infra" {
  lifecycle {
    # ACR must exist (discovered by type)
    precondition {
      condition     = local.discovered_acr_name != ""
      error_message = "No Microsoft.ContainerRegistry/registries resource found in resource group \"${data.azurerm_resource_group.base.name}\". Deploy base_infra first."
    }
  }
}
