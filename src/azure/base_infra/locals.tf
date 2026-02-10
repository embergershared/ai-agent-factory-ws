###############################################################################
# Locals – Naming conventions, common tags, derived values
###############################################################################

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

# Captured once at creation, stored in state, never changes on subsequent runs
resource "time_static" "created" {}

locals {
  # ── Naming prefix ────────────────────────────────────────────────────────
  # Pattern: <project>-<env>-<seq>  →  e.g. "pumps-dev-01"
  name_prefix = "${var.project_name}-${var.environment}-${var.sequence_number}"

  # For resources that don't allow hyphens (storage, cosmosdb, acr)
  name_prefix_clean = replace(local.name_prefix, "-", "")

  # Unique suffix for globally-unique names
  unique_suffix = random_string.suffix.result

  # ── Common tags applied to every resource ────────────────────────────────
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "spn-391575-terraform"
      CreatedDate = time_static.created.rfc3339
    },
    var.extra_tags,
  )

  # ── Identity ─────────────────────────────────────────────────────────────
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  # ── Resource names (centralised) ─────────────────────────────────────────
  resource_group_name = "rg-${local.name_prefix}"
  vnet_name           = "vnet-${local.name_prefix}"
  nsg_name_prefix     = "nsg-${local.name_prefix}"

  # Storage account: max 24 chars, lowercase alphanumeric only
  # "st" (2) + suffix (5) = 7 fixed chars → 17 chars for prefix
  storage_account_name = substr("st${local.name_prefix_clean}${local.unique_suffix}", 0, 24)

  # Key Vault: max 24 chars, alphanumeric + dashes
  # "kv-" (3) + "-" (1) + suffix (5) = 9 fixed chars → 15 chars for prefix
  key_vault_name          = substr("kv-${local.name_prefix}-${local.unique_suffix}", 0, 24)
  ai_search_name          = "srch-${local.name_prefix}"
  openai_name             = "oai-${local.name_prefix}"
  cognitive_services_name = "cog-${local.name_prefix}"
  cosmosdb_account_name   = "cosmos-${local.name_prefix}"
  acr_name                = "acr${local.name_prefix_clean}${local.unique_suffix}"
  aca_env_name            = "acaenv-${local.name_prefix}"
  log_analytics_name      = "log-${local.name_prefix}"

  # ── Subnet CIDR computation ─────────────────────────────────────────────
  # Carve /27 subnets (32 IPs each) from the VNet address space.
  # cidrsubnet(prefix, newbits, netnum) adds `newbits` to the prefix length
  # and selects the `netnum`-th subnet.
  #
  # For a /24 VNet: newbits = 3 gives /27 subnets (8 subnets of 32 IPs).
  # For a /16 VNet: newbits = 11 gives /27 subnets (2048 subnets of 32 IPs).
  #
  # We calculate newbits dynamically: target is /27, so newbits = 27 - vnet_prefix_length.
  vnet_prefix_length = tonumber(split("/", var.vnet_address_space)[1])
  subnet_newbits     = 27 - local.vnet_prefix_length

  # Computed subnet CIDRs
  subnet_cidrs = {
    default           = cidrsubnet(var.vnet_address_space, local.subnet_newbits, 0)
    aca               = cidrsubnet(var.vnet_address_space, local.subnet_newbits, 1)
    private-endpoints = cidrsubnet(var.vnet_address_space, local.subnet_newbits, 2)
    ai                = cidrsubnet(var.vnet_address_space, local.subnet_newbits, 3)
  }

  # Merge computed CIDRs with subnet metadata from the variable
  subnets = {
    for name, meta in var.subnets : name => merge(meta, {
      address_prefix = local.subnet_cidrs[name]
    })
  }

  # AI ML Workspace: max 33 chars, alphanumeric + dashes only
  ml_hub_name     = substr("aml-hub-${local.name_prefix}", 0, 33)
  ml_project_name = substr("aml-proj-${local.name_prefix}", 0, 33)

  # AI Foundry: max 33 chars, alphanumeric + dashes only
  ai_hub_name     = substr("aif-hub-${local.name_prefix}", 0, 33)
  ai_project_name = substr("aif-proj-${local.name_prefix}", 0, 33)

  # AI Services (Cognitive Account)
  ai_services_name        = "ais-${local.name_prefix}"
  ai_foundry_project_name = "aiproj-${local.name_prefix}"

  # App Registration (Entra ID)
  app_registration_name = "spn-391575-${local.name_prefix}"

  # Bot Service
  bot_service_name         = "az-bot-${local.name_prefix}"
  bot_service_display_name = "Agent Bot Service"
  bot_service_endpoint     = "https://${local.ai_services_name}.services.ai.azure.com/api/projects/${var.pump_foundry_project_name}/applications/${var.bot_service_agent_name}/protocols/activityprotocol?api-version=2025-11-15-preview"
}
