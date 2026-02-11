###############################################################################
# generate-env.ps1
#
# Generates a .env file for the foundry-sdk-python/deploy-pumps-agent app
# by reading Terraform outputs from the pumps-agent_infra deployment.
#
# Usage:
#   cd src/azure/pumps-agent_infra
#   terraform apply                  # if not already applied
#   pwsh ./generate-env.ps1          # generates the .env file
#
# The script must be run from the pumps-agent_infra directory (where the
# Terraform state lives).
###############################################################################
param(
  [string] $OutputPath = "../../../src/foundry-sdk-python/deploy-pumps-agent/.env",

  # Model deployment names (not managed by Terraform yet – override as needed)
  [string] $EmbeddingDeployment = "text-embedding-3-large",
  [string] $EmbeddingModel = "text-embedding-3-large",
  [string] $ChatDeployment = "gpt-5-mini",
  [string] $ChatModel = "gpt-5-mini"
)

$ErrorActionPreference = 'Stop'

Write-Host "Reading Terraform outputs..." -ForegroundColor Cyan

# Read all outputs as a JSON object
$json = terraform output -json | ConvertFrom-Json

# Extract values
$location = $json.location.value
$resourceGroup = $json.resource_group_name.value
$subscriptionId = $json.subscription_id.value
$foundryName = $json.foundry_resource_name.value
$projectName = $json.foundry_project_name.value
$searchName = $json.search_name.value
$searchKey = $json.search_primary_key.value
$storageAccount = $json.storage_account_name.value
$containerName = $json.container_name.value
$aoaiEndpoint = $json.aoai_endpoint.value
$aiServicesUri = $json.ai_services_endpoint.value

# Build the storage connection string using managed identity (ResourceId)
$storageId = $json.storage_account_id.value
$storageConnString = "ResourceId=$storageId;"

# Write the .env file
$envContent = @"
AZURE_LOCATION = "$location"
AZURE_RESOURCE_GROUP = "$resourceGroup"
AZURE_SUBSCRIPTION_ID = "$subscriptionId"
AZ_FOUNDRY_RESOURCE_NAME = "$foundryName"
AZ_FOUNDRY_PUMPS_PROJECT_NAME = "$projectName"
AZ_SEARCH_NAME="$searchName"
AZ_SEARCH_KEY="$searchKey"
STORAGE_ACCOUNT_NAME="$storageAccount"
STORAGE_ACCOUNT_CONTAINER_NAME="$containerName"
STORAGE_ACCOUNT_CONNECTION_STRING="$storageConnString"

# Azure OpenAI settings
AOAI_ENDPOINT="$aoaiEndpoint"
AOAI_EMBEDDING_DEPLOYMENT="$EmbeddingDeployment"
AOAI_EMBEDDING_MODEL_NAME="$EmbeddingModel"
AOAI_CHAT_DEPLOYMENT="$ChatDeployment"
AOAI_CHAT_MODEL_NAME="$ChatModel"

# Azure AI Services (Cognitive Services)
AI_SERVICES_URI="$aiServicesUri"
"@

$envContent | Out-File -FilePath $OutputPath -Encoding utf8NoBOM -Force
Write-Host "Generated .env file at: $(Resolve-Path $OutputPath)" -ForegroundColor Green
