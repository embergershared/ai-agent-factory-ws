###############################################################################
# Module: Azure Search Index Pipeline
#
# Creates all Azure Search data-plane resources via REST API calls:
#   1. Data Source     – blob connection to the storage account
#   2. Index           – search index with fields, vector search, semantic config
#   3. Skillset        – document extraction, chunking, vectorisation skills
#   4. Indexer         – orchestrates the pipeline (datasource → skillset → index)
#   5. Knowledge Source – Foundry IQ knowledge source pointing at the index
#   6. Knowledge Base   – Foundry IQ knowledge base wrapping the knowledge source
#
# Uses PUT (create-or-update) for idempotency.
# Each resource is created by a PowerShell script in the scripts/ subfolder
# to avoid Terraform template $-escaping issues with PowerShell syntax.
# Requires PowerShell (pwsh) on the Terraform runner.
###############################################################################

locals {
  search_url         = "https://${var.search_service_name}.search.windows.net"
  cog_subdomain_url  = "https://${var.cognitive_services_name}.cognitiveservices.azure.com/"
  ai_services_openai = "https://${var.ai_services_name}.openai.azure.com"
  scripts_dir        = replace("${path.module}/scripts", "/", "\\")

  # Resource names derived from the prefix
  datasource_name       = "${var.index_prefix}-datasource"
  index_name            = var.index_prefix
  skillset_name         = "${var.index_prefix}-skillset"
  indexer_name          = "${var.index_prefix}-indexer"
  knowledge_source_name = "${var.index_prefix}-knowledge-source"
  knowledge_base_name   = "${var.index_prefix}-knowledge-base"

  # Storage connection string (managed identity via ResourceId)
  storage_connection_string = "ResourceId=${var.storage_account_resource_id};"
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Data Source
#    Registers the blob storage connection (managed-identity based).
#    This is the first step; the indexer will later validate credentials.
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "datasource" {
  triggers_replace = {
    prefix             = var.index_prefix
    storage_account_id = var.storage_account_resource_id
    container_name     = var.blob_container_name
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-datasource.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.search_api_version}' -Name '${local.datasource_name}' -ConnectionString '${local.storage_connection_string}' -ContainerName '${var.blob_container_name}'"
  }
}

# Wait for the datasource REST call to settle before creating the index
resource "time_sleep" "after_datasource" {
  depends_on      = [terraform_data.datasource]
  create_duration = "5s"
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. Index
#    Defines the search index schema (fields, vector search, semantic config).
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "index" {
  depends_on = [time_sleep.after_datasource]

  triggers_replace = {
    prefix       = var.index_prefix
    cog_endpoint = local.cog_subdomain_url
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-index.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.search_api_version}' -IndexName '${local.index_name}' -CognitiveServicesUrl '${local.cog_subdomain_url}'"
  }
}

# Wait for the index REST call to settle before creating the skillset
resource "time_sleep" "after_index" {
  depends_on      = [terraform_data.index]
  create_duration = "5s"
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. Skillset
#    Document extraction, chunking, and vectorisation skills.
#    Depends on: Index (references index fields for projections).
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "skillset" {
  depends_on = [time_sleep.after_index]

  triggers_replace = {
    prefix       = var.index_prefix
    cog_endpoint = local.cog_subdomain_url
    storage_id   = var.storage_account_resource_id
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-skillset.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.search_api_version}' -SkillsetName '${local.skillset_name}' -IndexName '${local.index_name}' -CognitiveServicesUrl '${local.cog_subdomain_url}' -StorageConnectionString '${local.storage_connection_string}'"
  }
}

# Wait for the skillset REST call to settle before creating the indexer
resource "time_sleep" "after_skillset" {
  depends_on      = [terraform_data.skillset]
  create_duration = "5s"
}

# ─────────────────────────────────────────────────────────────────────────────
# 4. Indexer
#    Orchestrates the pipeline: datasource → skillset → index.
#    Depends on: Data Source, Index, Skillset (all three must exist).
#    This step validates the storage connection credentials at creation time.
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "indexer" {
  depends_on = [time_sleep.after_skillset]

  triggers_replace = {
    prefix = var.index_prefix
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-indexer.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.search_api_version}' -IndexerName '${local.indexer_name}' -DataSourceName '${local.datasource_name}' -SkillsetName '${local.skillset_name}' -IndexName '${local.index_name}'"
  }
}

# Wait for the indexer REST call to settle before creating the knowledge source
resource "time_sleep" "after_indexer" {
  depends_on      = [terraform_data.indexer]
  create_duration = "5s"
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. Knowledge Source (Foundry IQ)
#    Depends on: Indexer (index must be populated / pipeline must exist).
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "knowledge_source" {
  depends_on = [time_sleep.after_indexer]

  triggers_replace = {
    prefix     = var.index_prefix
    index_name = local.index_name
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-knowledge-source.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.knowledge_api_version}' -Name '${local.knowledge_source_name}' -IndexName '${local.index_name}'"
  }
}

# Wait for the knowledge source REST call to settle before creating the knowledge base
resource "time_sleep" "after_knowledge_source" {
  depends_on      = [terraform_data.knowledge_source]
  create_duration = "5s"
}

# ─────────────────────────────────────────────────────────────────────────────
# 6. Knowledge Base (Foundry IQ)
#    Depends on: Knowledge Source.
# ─────────────────────────────────────────────────────────────────────────────
resource "terraform_data" "knowledge_base" {
  depends_on = [time_sleep.after_knowledge_source]

  triggers_replace = {
    prefix             = var.index_prefix
    knowledge_source   = local.knowledge_source_name
    ai_services_openai = local.ai_services_openai
    chat_deployment    = var.chat_deployment_name
    chat_model         = var.chat_model_name
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${local.scripts_dir}\\create-knowledge-base.ps1' -SearchUrl '${local.search_url}' -ApiKey '${var.search_api_key}' -ApiVersion '${var.knowledge_api_version}' -Name '${local.knowledge_base_name}' -KnowledgeSourceName '${local.knowledge_source_name}' -AiServicesOpenAiUrl '${local.ai_services_openai}' -ChatDeploymentName '${var.chat_deployment_name}' -ChatModelName '${var.chat_model_name}'"
  }
}
