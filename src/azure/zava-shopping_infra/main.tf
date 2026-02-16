###############################################################################
# Main - Zava Shopping Multi-Agent Container App
#
# Deploys the zava-shopping-multi container image as a Container App in the
# same Container Apps Environment created by base_infra.
#
# The resource group is created by the base_infra deployment and referenced
# here via a data source (see data.tf).
###############################################################################

# ═══════════════════════════════════════════════════════════════════════════════
# 1. Build & push Zava Shopping container image to ACR
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
    image_name = var.zava_app_name
  }

  provisioner "local-exec" {
    command     = <<-EOT
      & '../../zava-agents/zava-shopping_bnp-to-acr.ps1' `
        -AcrName '${local.discovered_acr_name}' `
        -ImageName '${var.zava_app_name}'
    EOT
    interpreter = ["pwsh", "-NoProfile", "-Command"]
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. User-Assigned Managed Identity for ACR pull
#
#    Created before the Container App so the identity is ready and granted
#    AcrPull on the registry, avoiding the chicken-and-egg problem with
#    System-Assigned identities.
# ═══════════════════════════════════════════════════════════════════════════════
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = local.uai_aca_app_name
  location            = data.azurerm_resource_group.base.location
  resource_group_name = data.azurerm_resource_group.base.name
  tags                = local.common_tags
}

# Grant the identity AcrPull BEFORE the Container App is created
resource "azurerm_role_assignment" "aca_acr_pull" {
  scope                = data.azurerm_container_registry.base.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2b. RBAC: Grant the managed identity access to AI Services (Foundry)
#
#     The app uses AIProjectClient + DefaultAzureCredential to call GPT models,
#     embeddings, and agent APIs via the Foundry endpoint. These roles allow
#     the User-Assigned Managed Identity to obtain tokens for those operations.
# ═══════════════════════════════════════════════════════════════════════════════

# "Cognitive Services OpenAI User" — required for GPT & embedding calls
resource "azurerm_role_assignment" "aca_ai_services_openai_user" {
  scope                = data.azurerm_cognitive_account.app_foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# "Cognitive Services User" — required for AIProjectClient general operations
resource "azurerm_role_assignment" "aca_ai_services_user" {
  scope                = data.azurerm_cognitive_account.app_foundry.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# "Azure AI Developer" — required for agent write/action operations
# Scoped at the Foundry AI Services account's resource group to cover both
# CognitiveServices and MachineLearningServices permissions (Foundry
# projects map to ML workspaces that live in the same RG)
resource "azurerm_role_assignment" "aca_ai_developer" {
  scope                = data.azurerm_cognitive_account.app_foundry.id
  role_definition_name = "Azure AI Developer"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Container App - Zava Shopping Multi-Agent
#
#    Runs the zava-shopping-multi container image from ACR as a public HTTPS
#    WebSocket-enabled app inside the shared Container Apps Environment.
# ═══════════════════════════════════════════════════════════════════════════════
resource "azurerm_container_app" "zava_shopping" {
  name                         = local.aca_app_name
  resource_group_name          = data.azurerm_resource_group.base.name
  container_app_environment_id = data.azurerm_container_app_environment.base.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  depends_on = [
    azurerm_role_assignment.aca_acr_pull,
    azurerm_role_assignment.aca_ai_services_openai_user,
    azurerm_role_assignment.aca_ai_services_user,
    azurerm_role_assignment.aca_ai_developer,
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

  # ── Secrets (referenced by secret_name in env blocks) ────────────────────
  secret {
    name  = "foundry-key"
    value = var.foundry_key
  }
  secret {
    name  = "gpt-api-key"
    value = var.gpt_api_key
  }
  secret {
    name  = "phi-4-api-key"
    value = var.phi_4_api_key
  }
  secret {
    name  = "embedding-api-key"
    value = var.embedding_api_key
  }
  secret {
    name  = "subscription-key"
    value = var.subscription_key
  }
  secret {
    name  = "blob-connection-string"
    value = var.blob_connection_string
  }
  secret {
    name  = "cosmos-key"
    value = var.cosmos_key
  }
  secret {
    name  = "appinsights-connection-string"
    value = var.appinsights_connection_string
  }

  template {
    min_replicas = var.zava_container_min_replicas
    max_replicas = var.zava_container_max_replicas

    container {
      name   = local.aca_container_name
      image  = local.zava_container_image
      cpu    = var.zava_container_cpu
      memory = var.zava_container_memory

      # ── Identity ─────────────────────────────────────────────────────────
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.aca_identity.client_id
      }

      # ── OpenTelemetry ────────────────────────────────────────────────────
      env {
        name  = "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT"
        value = "true"
      }
      env {
        name  = "AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED"
        value = "true"
      }

      # ── Foundry ──────────────────────────────────────────────────────────
      env {
        name  = "FOUNDRY_ENDPOINT"
        value = var.foundry_endpoint
      }
      env {
        name        = "FOUNDRY_KEY"
        secret_name = "foundry-key"
      }
      env {
        name  = "FOUNDRY_API_VERSION"
        value = var.foundry_api_version
      }

      # ── GPT ──────────────────────────────────────────────────────────────
      env {
        name  = "gpt_endpoint"
        value = var.gpt_endpoint
      }
      env {
        name  = "gpt_deployment"
        value = var.gpt_deployment
      }
      env {
        name        = "gpt_api_key"
        secret_name = "gpt-api-key"
      }
      env {
        name  = "gpt_api_version"
        value = var.gpt_api_version
      }

      # ── Phi-4 ────────────────────────────────────────────────────────────
      env {
        name  = "phi_4_endpoint"
        value = var.phi_4_endpoint
      }
      env {
        name  = "phi_4_deployment"
        value = var.phi_4_deployment
      }
      env {
        name        = "phi_4_api_key"
        secret_name = "phi-4-api-key"
      }
      env {
        name  = "phi_4_api_version"
        value = var.phi_4_api_version
      }

      # ── Embedding ────────────────────────────────────────────────────────
      env {
        name  = "embedding_endpoint"
        value = var.embedding_endpoint
      }
      env {
        name  = "embedding_deployment"
        value = var.embedding_deployment
      }
      env {
        name        = "embedding_api_key"
        secret_name = "embedding-api-key"
      }
      env {
        name  = "embedding_api_version"
        value = var.embedding_api_version
      }

      # ── Image Generation (gpt-image-1) ──────────────────────────────────
      env {
        name  = "gpt-image-1-endpoint"
        value = var.gpt_image_1_endpoint
      }
      env {
        name  = "gpt-image-1-deployment"
        value = var.gpt_image_1_deployment
      }
      env {
        name  = "gpt-image-1-api_version"
        value = var.gpt_image_1_api_version
      }
      env {
        name        = "subscription_key"
        secret_name = "subscription-key"
      }

      # ── Storage ──────────────────────────────────────────────────────────
      env {
        name        = "blob_connection_string"
        secret_name = "blob-connection-string"
      }
      env {
        name  = "storage_account_name"
        value = var.storage_account_name
      }
      env {
        name  = "storage_container_name"
        value = var.storage_container_name
      }

      # ── Cosmos DB ────────────────────────────────────────────────────────
      env {
        name  = "COSMOS_ENDPOINT"
        value = var.cosmos_endpoint
      }
      env {
        name        = "COSMOS_KEY"
        secret_name = "cosmos-key"
      }
      env {
        name  = "DATABASE_NAME"
        value = var.cosmos_database_name
      }
      env {
        name  = "CONTAINER_NAME"
        value = var.cosmos_container_name
      }

      # ── Application Insights ────────────────────────────────────────────
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }

      # ── MCP Server ──────────────────────────────────────────────────────
      env {
        name  = "MCP_SERVER_URL"
        value = var.mcp_server_url
      }

      # ── Agent IDs ───────────────────────────────────────────────────────
      env {
        name  = "customer_loyalty"
        value = var.agent_customer_loyalty
      }
      env {
        name  = "inventory_agent"
        value = var.agent_inventory
      }
      env {
        name  = "interior_designer"
        value = var.agent_interior_designer
      }
      env {
        name  = "cora"
        value = var.agent_cora
      }
      env {
        name  = "cart_manager"
        value = var.agent_cart_manager
      }
      env {
        name  = "handoff_service"
        value = var.agent_handoff_service
      }
    }
  }

  tags = local.common_tags
}
