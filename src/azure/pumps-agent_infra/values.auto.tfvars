###############################################################################
# Variable values - pumps-agent_infra
###############################################################################

# Base infrastructure (all resource names are derived from the RG name)
base_infra_rg_name = "rg-swc-s3-ai-msfoundry-demo-02"

# Storage
manuals_storage_name_suffix = "pumpsmanuals"
storage_account_tier        = "Standard"
storage_replication_type    = "LRS"

# Container Apps
mcp_api_key = "dev-secret"

# Foundry / Demo project
pump_foundry_project_name        = "pumps-project"
pump_foundry_project_description = "Demo project in Foundry v2 to show case pumps-manuals and multi-agent-chatbot agents."

# Foundry Model Deployments
# Model formats and names: az cognitiveservices model list -l <location> \
#   --query "[].{Format: model.format, Name: model.name}" -o table
foundry_model_deployments = {
  "DeepSeek-V3.2" = {
    model_name    = "DeepSeek-V3.2"
    model_version = "1"
    model_format  = "DeepSeek"
    sku_name      = "GlobalStandard"
    sku_capacity  = 500
  }
  "Phi-4" = {
    model_name    = "Phi-4"
    model_version = "7"
    model_format  = "Microsoft"
    sku_name      = "GlobalStandard"
    sku_capacity  = 1
  }
  # "Phi-4-mini-instruct" = {
  #   model_name    = "Phi-4-mini-instruct"
  #   model_version = "1"
  #   model_format  = "Microsoft"
  #   sku_name      = "GlobalStandard"
  #   sku_capacity  = 1
  # }
  "Kimi-K2.5" = {
    model_name    = "Kimi-K2.5"
    model_version = "1"
    model_format  = "MoonshotAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 50
  }
  "gpt-5.2" = {
    model_name    = "gpt-5.2"
    model_version = "2025-12-11"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 250
  }
  "gpt-5.2-chat" = {
    model_name    = "gpt-5.2-chat"
    model_version = "2025-12-11"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 250
  }
  "gpt-5.2-codex" = {
    model_name    = "gpt-5.2-codex"
    model_version = "2026-01-14"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 500
  }
  "grok-4" = {
    model_name    = "grok-4"
    model_version = "1"
    model_format  = "xAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 500
  }
  "Mistral-Large-3" = {
    model_name    = "Mistral-Large-3"
    model_version = "1"
    model_format  = "Mistral AI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 125
  }
  "text-embedding-3-large" = {
    model_name    = "text-embedding-3-large"
    model_version = "1"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 500
  }
  "text-embedding-ada-002" = {
    model_name    = "text-embedding-ada-002"
    model_version = "2"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 200
  }
  "gpt-image-1.5" = {
    model_name    = "gpt-image-1.5"
    model_version = "2025-12-16"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 5
  }
  "model-router" = {
    model_name    = "model-router"
    model_version = "2025-08-07"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 250
  }
  "sora-2" = {
    model_name    = "sora-2"
    model_version = "2025-10-06"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 5
  }
  "gpt-5-pro" = {
    model_name    = "gpt-5-pro"
    model_version = "2025-10-06"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 80
  }
  "Llama-3.3-70B-Instruct" = {
    model_name    = "Llama-3.3-70B-Instruct"
    model_version = "1"
    model_format  = "Meta"
    sku_name      = "GlobalStandard"
    sku_capacity  = 1
  }
  gpt-5-mini = {
    model_name    = "gpt-5-mini"
    model_version = "2025-08-07"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 250
  }
  text-embedding-3-small = {
    model_name    = "text-embedding-3-small"
    model_version = "1"
    model_format  = "OpenAI"
    sku_name      = "GlobalStandard"
    sku_capacity  = 250
  }
  "FLUX.2-pro" = {
    model_name    = "FLUX.2-pro"
    model_version = "1"
    model_format  = "Black Forest Labs"
    sku_name      = "GlobalStandard"
    sku_capacity  = 4
  }
}
