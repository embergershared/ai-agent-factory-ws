###############################################################################
# Data Sources - Reference existing resources from base_infra
#
# The base_infra naming convention is:
#   name_prefix       = "<project>-<env>-<seq>"        (e.g. swec-s3-ai-foundry-demo-01)
#   name_prefix_clean = replace(name_prefix, "-", "")  (e.g. swecs3aifoundrydemo01)
#   unique_suffix     = random_string(3)               (e.g. j0e)
#
# Resource names follow deterministic patterns documented in base_infra/locals.tf.
# We parse the RG name ("rg-<name_prefix>") to recover name_prefix, then
# compute every dependency name—except for the ACR, which includes a random
# suffix that must be discovered at runtime.
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
  computed_search_name             = "srch-${local.base_infra_name_prefix}"
  computed_aca_env_name            = "aca-env-${local.base_infra_name_prefix}"
  computed_ai_services_name        = "aisvc-res-${local.base_infra_name_prefix}"
  computed_cognitive_services_name = "cogsvc-${local.base_infra_name_prefix}"
  computed_openai_name             = "azopenai-${local.base_infra_name_prefix}"
}

# ─── Discovery: ACR includes a random suffix we cannot predict ───────────────
data "azurerm_resources" "container_registries" {
  resource_group_name = data.azurerm_resource_group.base.name
  type                = "Microsoft.ContainerRegistry/registries"
}

locals {
  # Take the first (and expected only) ACR in the resource group
  discovered_acr_name = try(data.azurerm_resources.container_registries.resources[0].name, "")

  # The suffix is the trailing characters after "acr" + name_prefix_clean.
  # base_infra builds it as: acr${name_prefix_clean}${random_string(3)}
  discovered_base_infra_suffix = try(
    trimprefix(local.discovered_acr_name, "acr${local.base_infra_name_prefix_clean}"),
    ""
  )
}

# ─── Typed data sources (for full attribute access) ──────────────────────────

# Azure AI Search service
data "azurerm_search_service" "base" {
  name                = local.computed_search_name
  resource_group_name = data.azurerm_resource_group.base.name
}

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

# AI Services (Foundry) account - the parent for projects (kind = AIServices)
data "azurerm_cognitive_account" "foundry" {
  name                = local.computed_ai_services_name
  resource_group_name = data.azurerm_resource_group.base.name
}

# Cognitive Services (multi-service) account (kind = CognitiveServices)
data "azurerm_cognitive_account" "cognitive" {
  name                = local.computed_cognitive_services_name
  resource_group_name = data.azurerm_resource_group.base.name
}

# Azure OpenAI account (kind = OpenAI)
data "azurerm_cognitive_account" "openai" {
  name                = local.computed_openai_name
  resource_group_name = data.azurerm_resource_group.base.name
}

# ─── Validation: fail early if a required resource is missing ────────────────
resource "terraform_data" "validate_base_infra" {
  lifecycle {
    # ACR must exist (discovered by type)
    precondition {
      condition     = local.discovered_acr_name != ""
      error_message = "No Microsoft.ContainerRegistry/registries resource found in resource group \"${data.azurerm_resource_group.base.name}\". Deploy base_infra first."
    }
    # Suffix must have been extracted successfully
    precondition {
      condition     = local.discovered_base_infra_suffix != ""
      error_message = "Could not extract the random suffix from ACR name \"${local.discovered_acr_name}\". Expected pattern: acr<prefix_clean><suffix>."
    }
  }
}
