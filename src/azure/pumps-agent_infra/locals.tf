###############################################################################
# Locals - Naming conventions, common tags
###############################################################################

locals {
  # ── Naming ───────────────────────────────────────────────────────────────
  # pumps-agent resources use the base_infra naming prefix + random suffix
  name_prefix_clean = local.base_infra_name_prefix_clean

  # Reuse the 3-char random suffix from base_infra (extracted in data.tf)
  unique_suffix = local.discovered_base_infra_suffix

  # ── Resource names ───────────────────────────────────────────────────────
  # Storage: st<base_prefix_clean><suffix><unique>  (max 24 chars)
  storage_account_name = substr("st${var.storage_name_suffix}${local.unique_suffix}", 0, 24)
  uai_aca_app_name     = "uaid-aca-app-${var.mcp_app_name}"
  aca_app_name         = "aca-app-${var.mcp_app_name}"
  aca_container_name   = "${replace(var.mcp_app_name, "-", "")}-container"

  # Container image reference (derived from discovered ACR)
  mcp_container_image = "${data.azurerm_container_registry.base.login_server}/${var.mcp_app_name}:latest"

  # ── Common tags ──────────────────────────────────────────────────────────
  common_tags = {
    Project   = local.base_infra_name_prefix
    ManagedBy = "Terraform"
  }
}
