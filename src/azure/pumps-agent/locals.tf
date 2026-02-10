###############################################################################
# Locals – Naming conventions, common tags
###############################################################################

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  # ── Naming prefix ────────────────────────────────────────────────────────
  name_prefix       = "${var.project_name}-${var.environment}-${var.sequence_number}"
  name_prefix_clean = replace(local.name_prefix, "-", "")
  unique_suffix     = random_string.suffix.result

  # ── Base infra resource group name (must match base_infra naming) ────────
  base_infra_env     = coalesce(var.base_infra_environment, var.environment)
  base_infra_seq     = coalesce(var.base_infra_sequence_number, var.sequence_number)
  base_infra_rg_name = "rg-${var.base_infra_project_name}-${local.base_infra_env}-${local.base_infra_seq}"

  # ── Resource names ───────────────────────────────────────────────────────
  storage_account_name = substr("st${local.name_prefix_clean}${local.unique_suffix}", 0, 24)

  # ── Common tags ──────────────────────────────────────────────────────────
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.extra_tags,
  )
}
