###############################################################################
# Locals - Naming conventions, common tags
###############################################################################

locals {
  # ── Resource names ───────────────────────────────────────────────────────
  uai_aca_app_name   = "uaid-aca-app-${var.zava_app_name}"
  aca_app_name       = "aca-app-${var.zava_app_name}"
  aca_container_name = "${replace(var.zava_app_name, "-", "")}-container"

  # Container image reference (derived from discovered ACR)
  zava_container_image = "${data.azurerm_container_registry.base.login_server}/${var.zava_app_name}:latest"

  # ── Common tags ──────────────────────────────────────────────────────────
  common_tags = {
    Project   = local.base_infra_name_prefix
    ManagedBy = "Terraform"
  }
}
