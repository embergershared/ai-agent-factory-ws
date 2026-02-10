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

# ═══════════════════════════════════════════════════════════════════════════════
# 6. Container App – MCP Pump Switch
#
#    Runs the mcp-pump-switch container image from ACR as a public HTTPS site
#    inside the Container Apps Environment created by base_infra.
#
#    A User-Assigned Managed Identity is created first and granted AcrPull
#    on the registry BEFORE the Container App is created, avoiding the
#    chicken-and-egg problem with System-Assigned identities.
# ═══════════════════════════════════════════════════════════════════════════════

# 6a. User-Assigned Managed Identity for ACR pull
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "id-ca-mcp-pump-switch"
  location            = data.azurerm_resource_group.base.location
  resource_group_name = data.azurerm_resource_group.base.name
  tags                = local.common_tags
}

# 6b. Grant the identity AcrPull BEFORE the Container App is created
resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = data.azurerm_container_registry.base.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# 6c. Container App
resource "azurerm_container_app" "mcp_pump_switch" {
  name                         = "aca-app-mcp-pump-switch"
  resource_group_name          = data.azurerm_resource_group.base.name
  container_app_environment_id = data.azurerm_container_app_environment.base.id
  revision_mode                = "Single"

  depends_on = [azurerm_role_assignment.aca_acr_pull]

  # Pull image from ACR using the pre-configured managed identity
  registry {
    server   = data.azurerm_container_registry.base.login_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "mcp-pump-switch"
      image  = var.mcp_container_image
      cpu    = var.mcp_container_cpu
      memory = var.mcp_container_memory

      env {
        name  = "MCP_API_KEY"
        value = var.mcp_api_key
      }
    }
  }

  tags = local.common_tags
}

# Create the code to deploy "text-embedding-ada-002" in Azure Open AI oai-swc-s3-ai-foundryv2-demo-01

resource "azurerm_openai_deployment" "text_embedding_ada_002" {
  name                = "text-embedding-ada-002"
  resource_group_name = data.azurerm_resource_group.base.name
  location            = data.azurerm_resource_group.base.location
  model               = "text-embedding-ada-002"
  version             = "2024-02-15"
  tags                = local.common_tags
}

# Create the code to deploy "gpt-5" in Azure Open AI oai-swc-s3-ai-foundryv2-demo-01

resource "azurerm_openai_deployment" "gpt_5" {
  name                = "gpt-5"
  resource_group_name = data.azurerm_resource_group.base.name
  location            = data.azurerm_resource_group.base.location
  model               = "gpt-5"
  version             = "2024-02-15"
  tags                = local.common_tags
}

# Assign "Storage Blob Data Contributor" for Azure Search ID on Storage account container (Reader is enough got KS, but Contributor is needed for multimodal RAG embeddings of images, since it writes in a blob container)

# Assign "Cognitive Services User" for Azure Search ID role on the Foundry resource (Error: Unable to connect to AI Services using managed identity. Ensure the identity has been granted permission Cognitive Services User on the AI Service.)


# Foundry IQ settings
## requires to connect Foundry to an Azure Search

# Then create the indexes in Azure Search


# Create MCP tool
# Connection:
## MCP server endpoint: https://aca-app-mcp-pump-switch.yellowcliff-006a1b15.swedencentral.azurecontainerapps.io/mcp
## Authentication: Key-based
## Credential:
##      X-API-Key: "${var.mcp_api_key}"


# Publish agent
# https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/publish-agent?view=foundry

