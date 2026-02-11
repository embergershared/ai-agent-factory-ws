###############################################################################
# Main - Manuals Storage: Storage Account, Container & Folder
#
# The resource group is created by the base_infra deployment and referenced
# here via a data source (see data.tf).
###############################################################################

# ═══════════════════════════════════════════════════════════════════════════════
# 1. Build & push MCP container image to ACR
#
#    Runs the build-and-push-to-acr.ps1 script, passing the discovered ACR
#    name so the image lands in the right registry.  Re-runs whenever the
#    ACR name or image tag changes.
#
#    PREREQUISITE: Run `az login` before `terraform plan/apply` so that the
#                  Azure CLI session is available for `az acr login`.
#                  Docker Desktop must be installed and running.
# ═══════════════════════════════════════════════════════════════════════════════
resource "terraform_data" "build_and_push_image" {
  depends_on = [terraform_data.validate_base_infra]

  triggers_replace = {
    acr_name   = local.discovered_acr_name
    image_name = var.mcp_app_name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      & '../../pump-switch-mcp-server/build-and-push-to-acr.ps1' `
        -AcrName '${local.discovered_acr_name}' `
        -ImageName '${var.mcp_app_name}'
    EOT
    interpreter = ["pwsh", "-NoProfile", "-Command"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. Storage Account
# ═══════════════════════════════════════════════════════════════════════════════
module "manuals_storage_account" {
  source = "../modules/storage_account"

  name                = local.manuals_storage_account_name
  resource_group_name = data.azurerm_resource_group.base.name
  location            = data.azurerm_resource_group.base.location
  account_tier        = var.storage_account_tier
  replication_type    = var.storage_replication_type
  tags                = local.common_tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Blob Container (for manuals)
# ═══════════════════════════════════════════════════════════════════════════════
module "manuals_container" {
  source = "../modules/storage_container"

  name               = var.container_name
  storage_account_id = module.manuals_storage_account.id
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. Virtual folder (empty marker blob to create the "pdfs/" folder)
#
#    Azure Blob Storage has no native folder concept. A zero-byte blob whose
#    name ends with "/" creates the virtual directory in portal & SDKs.
# ═══════════════════════════════════════════════════════════════════════════════
# resource "azurerm_storage_blob" "folder_marker" {
#   name                   = "${var.folder_name}/.folder"
#   storage_account_name   = module.manuals_storage_account.name
#   storage_container_name = module.manuals_container.name
#   type                   = "Block"
#   content_type           = "application/octet-stream"
#   source_content         = ""
# }

# ═══════════════════════════════════════════════════════════════════════════════
# 5. Upload PDF manuals to blob container via azcopy
#
#    Uses azcopy.exe (located in this Terraform folder) to upload all PDFs
#    from src/manuals-pdfs/ into the blob container.
#    azcopy authenticates via the Service Principal credentials passed as
#    environment variables.
#
#    Re-runs whenever the container name or storage account name changes.
# ═══════════════════════════════════════════════════════════════════════════════

# 5a. Grant the Terraform SP data-plane access to upload blobs
module "sp_storage_blob_contributor" {
  source = "../modules/role_assignment"

  scope                = module.manuals_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# 5b. Upload manuals
resource "terraform_data" "upload_manuals" {
  depends_on = [
    module.manuals_container,
    module.sp_storage_blob_contributor,
  ]

  # Re-upload when the target container or storage account changes
  triggers_replace = {
    storage_account = module.manuals_storage_account.name
    container       = module.manuals_container.name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $env:AZCOPY_SPA_CLIENT_SECRET = '${var.client_secret}'
      ./azcopy login --service-principal --application-id '${var.client_id}' --tenant-id '${var.tenant_id}'
      if ($LASTEXITCODE -ne 0) { throw 'azcopy login failed' }
      ./azcopy copy '../../manuals-pdfs/*' 'https://${module.manuals_storage_account.name}.blob.core.windows.net/${module.manuals_container.name}/' --recursive
      if ($LASTEXITCODE -ne 0) { throw 'azcopy copy failed' }
    EOT
    interpreter = ["pwsh", "-NoProfile", "-Command"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. AI Foundry Project
# ═══════════════════════════════════════════════════════════════════════════════
module "ai_foundry_project" {
  source = "../modules/ai_foundry_project"

  project_name           = var.pump_foundry_project_name
  project_description    = var.pump_foundry_project_description
  ai_services_account_id = data.azurerm_cognitive_account.foundry.id
  location               = data.azurerm_resource_group.base.location
  tags                   = local.common_tags
}


# ═══════════════════════════════════════════════════════════════════════════════
# 7. Container App - MCP Pump Switch
#
#    Runs the mcp-pump-switch container image from ACR as a public HTTPS site
#    inside the Container Apps Environment created by base_infra.
#
#    A User-Assigned Managed Identity is created first and granted AcrPull
#    on the registry BEFORE the Container App is created, avoiding the
#    chicken-and-egg problem with System-Assigned identities.
# ═══════════════════════════════════════════════════════════════════════════════

# 7a. User-Assigned Managed Identity for ACR pull
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = local.uai_aca_app_name
  location            = data.azurerm_resource_group.base.location
  resource_group_name = data.azurerm_resource_group.base.name
  tags                = local.common_tags
}

# 7b. Grant the identity AcrPull BEFORE the Container App is created
resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = data.azurerm_container_registry.base.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# 7c. Container App for the Pump valve switch MCP server
resource "azurerm_container_app" "mcp_pump_switch" {
  name                         = local.aca_app_name
  resource_group_name          = data.azurerm_resource_group.base.name
  container_app_environment_id = data.azurerm_container_app_environment.base.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  depends_on = [
    azurerm_role_assignment.aca_acr_pull,
    terraform_data.build_and_push_image,
  ]

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
      name   = local.aca_container_name
      image  = local.mcp_container_image
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

# OpenAI model deployments, in Azure OpenAI, to support Multimodal RAG processing.
module "text_embedding_ada_002_deployment" {
  source = "../modules/az_openai_deployment"

  cognitive_account_id = data.azurerm_cognitive_account.openai.id
  deployment_name      = "text-embedding-ada-002"

  model_format  = "OpenAI"
  model_name    = "text-embedding-ada-002"
  model_version = "2"
}

module "gpt_5_deployment" {
  source = "../modules/az_openai_deployment"

  cognitive_account_id = data.azurerm_cognitive_account.openai.id

  model_format    = "OpenAI"
  deployment_name = "gpt-4.1"
  model_name      = "gpt-4.1"
  model_version   = "2025-04-14"
}

# Assign "Storage Blob Data Contributor" for Azure Search ID on Storage account container (Reader is enough got KS, but Contributor is needed for multimodal RAG embeddings of images, since it writes in a blob container)
module "search_storage_blob_contributor" {
  source = "../modules/role_assignment"

  scope                = module.manuals_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_search_service.base.identity[0].principal_id
}

# Assign "Cognitive Services User" for Azure Search ID role on the Foundry resource (Error: Unable to connect to AI Services using managed identity. Ensure the identity has been granted permission Cognitive Services User on the AI Service.)
module "search_cognitive_services_user" {
  source = "../modules/role_assignment"

  scope                = data.azurerm_cognitive_account.cognitive.id
  role_definition_name = "Cognitive Services User"
  principal_id         = data.azurerm_search_service.base.identity[0].principal_id
}


# ═══════════════════════════════════════════════════════════════════════════════
# 8. Azure Search Index Pipeline (Multimodal RAG)
#
#    Creates the full search index pipeline via REST API calls:
#    datasource → index → skillset → indexer → knowledge source → knowledge base
# ═══════════════════════════════════════════════════════════════════════════════
module "search_index" {
  source = "../modules/az_search_index"

  index_prefix = var.search_index_prefix

  search_service_name         = data.azurerm_search_service.base.name
  search_api_key              = data.azurerm_search_service.base.primary_key
  search_api_version          = var.search_index_api_version
  knowledge_api_version       = var.search_knowledge_api_version
  cognitive_services_name     = data.azurerm_cognitive_account.cognitive.name
  ai_services_name            = data.azurerm_cognitive_account.foundry.name
  storage_account_resource_id = module.manuals_storage_account.id
  blob_container_name         = var.container_name
  chat_deployment_name        = var.search_kb_chat_deployment
  chat_model_name             = var.search_kb_chat_model

  depends_on = [
    module.search_storage_blob_contributor,
    module.search_cognitive_services_user,
    terraform_data.upload_manuals,
  ]
}


# Create MCP tool
# Connection:
## MCP server endpoint: https://aca-app-mcp-pump-switch.yellowcliff-006a1b15.swedencentral.azurecontainerapps.io/mcp
## Authentication: Key-based
## Credential:
##      X-API-Key: "${var.mcp_api_key}"


# Create the tool that links to Azure Search


# Create the agent

# Publish agent
# https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/publish-agent?view=foundry





