###############################################################################
# Variable values - zava-shopping_infra
###############################################################################

# Base infrastructure (all resource names are derived from the RG name)
base_infra_rg_name = "rg-swc-s3-ai-msfoundry-demo-02"

# Foundry AI Services account the app connects to
foundry_ai_services_name    = "zava-shopping-agent-resource"
foundry_ai_services_rg_name = "rg-swc-s3-ai-msfoundry-demo-02"

# Container App
zava_app_name               = "zava-shopping-multi"
zava_container_cpu          = 1.0
zava_container_memory       = "2Gi"
zava_container_min_replicas = 0
zava_container_max_replicas = 1

# ── Foundry ──────────────────────────────────────────────────────────────────
foundry_endpoint    = "https://zava-shopping-agent-resource.services.ai.azure.com/api/projects/zava-shopping-agent"
foundry_api_version = "2025-01-01-preview"

# ── GPT ──────────────────────────────────────────────────────────────────────
gpt_endpoint    = "https://zava-shopping-agent-resource.cognitiveservices.azure.com"
gpt_deployment  = "gpt-5-mini"
gpt_api_version = "2025-01-01-preview"

# ── Phi-4 ────────────────────────────────────────────────────────────────────
phi_4_endpoint    = "https://zava-shopping-agent-resource.services.ai.azure.com/models"
phi_4_deployment  = "Phi-4"
phi_4_api_version = "2024-05-01-preview"

# ── Embedding ────────────────────────────────────────────────────────────────
embedding_endpoint    = "https://zava-shopping-agent-resource.cognitiveservices.azure.com"
embedding_deployment  = "text-embedding-3-large"
embedding_api_version = "2025-01-01-preview"

# ── Image Generation ─────────────────────────────────────────────────────────
gpt_image_1_endpoint    = "https://zava-shopping-agent-resource.cognitiveservices.azure.com"
gpt_image_1_deployment  = "gpt-image-1"
gpt_image_1_api_version = "2025-01-01-preview"

# ── Storage ──────────────────────────────────────────────────────────────────
storage_account_name   = "stswcs3aimsfoundrydemo02"
storage_container_name = "zava"

# ── Cosmos DB ────────────────────────────────────────────────────────────────
cosmos_endpoint       = "https://cosmos-swc-s3-ai-msfoundry-demo-02.documents.azure.com:443/"
cosmos_database_name  = "zava"
cosmos_container_name = "product_catalog"

# ── MCP Server ───────────────────────────────────────────────────────────────
mcp_server_url = "http://localhost:8000/mcp-inventory/sse"

# ── Agent IDs ────────────────────────────────────────────────────────────────
agent_customer_loyalty  = "customer-loyalty"
agent_inventory         = "inventory-agent"
agent_interior_designer = "interior-designer"
agent_cora              = "cora"
agent_cart_manager      = "cart-manager"
agent_handoff_service   = "handoff-service"
