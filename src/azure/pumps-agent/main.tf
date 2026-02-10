###############################################################################
# Main – Manuals Storage: Storage Account, Container & Folder
#
# The resource group is created by the base_infra deployment and referenced
# here via a data source (see data.tf).
###############################################################################

# ═══════════════════════════════════════════════════════════════════════════════
# 1. Storage Account
# ═══════════════════════════════════════════════════════════════════════════════
module "storage_account" {
  source = "../modules/storage_account"

  name                = local.storage_account_name
  resource_group_name = data.azurerm_resource_group.base.name
  location            = data.azurerm_resource_group.base.location
  account_tier        = var.storage_account_tier
  replication_type    = var.storage_replication_type
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. Blob Container (for manuals)
# ═══════════════════════════════════════════════════════════════════════════════
module "manuals_container" {
  source = "../modules/storage_container"

  name               = var.container_name
  storage_account_id = module.storage_account.id
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Virtual folder (empty marker blob to create the "pdfs/" folder)
#
#    Azure Blob Storage has no native folder concept. A zero-byte blob whose
#    name ends with "/" creates the virtual directory in portal & SDKs.
# ═══════════════════════════════════════════════════════════════════════════════
resource "azurerm_storage_blob" "folder_marker" {
  name                   = "${var.folder_name}/.folder"
  storage_account_name   = module.storage_account.name
  storage_container_name = module.manuals_container.name
  type                   = "Block"
  content_type           = "application/octet-stream"
  source_content         = ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. Upload PDF manuals to blob container via azcopy
#
#    Uses azcopy.exe (located in this Terraform folder) to upload all PDFs
#    from src/pumps-agent/manuals/pdfs/ into the blob container.
#    azcopy authenticates via the Service Principal credentials passed as
#    environment variables.
#
#    Re-runs whenever the container name or storage account name changes.
# ═══════════════════════════════════════════════════════════════════════════════
resource "terraform_data" "upload_manuals" {
  depends_on = [
    module.manuals_container,
    azurerm_storage_blob.folder_marker,
  ]

  # Re-upload when the target container or storage account changes
  triggers_replace = {
    storage_account = module.storage_account.name
    container       = module.manuals_container.name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      $env:AZCOPY_SPA_CLIENT_SECRET = '${var.client_secret}'
      ./azcopy login --service-principal --application-id '${var.client_id}' --tenant-id '${var.tenant_id}'
      ./azcopy copy '../../pumps-agent/manuals/pdfs/*' 'https://${module.storage_account.name}.blob.core.windows.net/${module.manuals_container.name}/${var.folder_name}/' --recursive
    EOT
    interpreter = ["pwsh", "-NoProfile", "-Command"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 5. AI Foundry Project
# ═══════════════════════════════════════════════════════════════════════════════
module "ai_foundry_project" {
  source = "../modules/ai_foundry_project"

  project_name           = var.pump_foundry_project_name
  project_description    = var.pump_foundry_project_description
  ai_services_account_id = data.azurerm_cognitive_account.base.id
  location               = data.azurerm_resource_group.base.location
  tags                   = local.common_tags
}


