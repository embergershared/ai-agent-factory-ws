# =============================================================================
# Deploy MCP Server to Azure Web App
# =============================================================================
# Prerequisites:
#   - Azure CLI installed and logged in (az login)
#   - An existing Azure Web App (Python 3.11+ runtime)
#
# Usage:
#   .\deploy-to-azure.ps1 -ResourceGroupName "your-rg" -WebAppName "your-webapp"
#
# =============================================================================

param(
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
    
  [Parameter(Mandatory = $true)]
  [string]$WebAppName,
    
  [Parameter(Mandatory = $false)]
  [string]$McpApiKey = ""
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying MCP Server to Azure Web App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Web App Name:   $WebAppName"
Write-Host ""

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
  exit 1
}

# Check if logged in to Azure
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
  Write-Host "Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
  az login
}

Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host ""

# Configure the Web App settings
Write-Host "Configuring Web App settings..." -ForegroundColor Yellow

# Set the startup command - install dependencies first, then start uvicorn
az webapp config set `
  --resource-group $ResourceGroupName `
  --name $WebAppName `
  --startup-file "pip install -r requirements.txt && python -m uvicorn mcp-server:app --host 0.0.0.0 --port 8000"

# Set application settings
$appSettings = @(
  "WEBSITES_PORT=8000"
  "SCM_DO_BUILD_DURING_DEPLOYMENT=true"
)

if ($McpApiKey) {
  $appSettings += "MCP_API_KEY=$McpApiKey"
  Write-Host "MCP_API_KEY will be set from parameter" -ForegroundColor Green
}
else {
  Write-Host "WARNING: MCP_API_KEY not provided. Set it manually in Azure Portal or use -McpApiKey parameter" -ForegroundColor Yellow
}

az webapp config appsettings set `
  --resource-group $ResourceGroupName `
  --name $WebAppName `
  --settings $appSettings

Write-Host "App settings configured." -ForegroundColor Green
Write-Host ""

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow

$deployDir = Join-Path $PSScriptRoot "deploy-package"
$zipPath = Join-Path $PSScriptRoot "deploy.zip"

# Clean up previous deployment artifacts
if (Test-Path $deployDir) { Remove-Item $deployDir -Recurse -Force }
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# Create deployment directory
New-Item -ItemType Directory -Path $deployDir | Out-Null

# Copy required files
Copy-Item (Join-Path $PSScriptRoot "mcp-server.py") $deployDir
Copy-Item (Join-Path $PSScriptRoot "requirements.txt") $deployDir
Copy-Item (Join-Path $PSScriptRoot "static") $deployDir -Recurse

# Create zip package
Compress-Archive -Path "$deployDir\*" -DestinationPath $zipPath -Force

Write-Host "Deployment package created: $zipPath" -ForegroundColor Green
Write-Host ""

# Deploy to Azure
Write-Host "Deploying to Azure Web App..." -ForegroundColor Yellow

az webapp deploy `
  --resource-group $ResourceGroupName `
  --name $WebAppName `
  --src-path $zipPath `
  --type zip

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Get the Web App URL
$webAppUrl = az webapp show `
  --resource-group $ResourceGroupName `
  --name $WebAppName `
  --query "defaultHostName" `
  --output tsv

Write-Host "Web App URL: https://$webAppUrl" -ForegroundColor Cyan
Write-Host "MCP Endpoint: https://$webAppUrl/mcp" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "# Check API state"
Write-Host "curl.exe -s https://$webAppUrl/api/state"
Write-Host ""
Write-Host "# Initialize MCP session"
Write-Host "`$body = '{`"jsonrpc`":`"2.0`",`"id`":1,`"method`":`"initialize`",`"params`":{`"protocolVersion`":`"2024-11-05`",`"capabilities`":{},`"clientInfo`":{`"name`":`"powershell`",`"version`":`"0.1`"}}}'"
Write-Host "curl.exe -i https://$webAppUrl/mcp -H `"Content-Type: application/json`" -H `"Accept: application/json, text/event-stream`" -H `"X-API-Key: <YOUR_MCP_API_KEY>`" -d `$body"
Write-Host ""

# Clean up
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item $deployDir -Recurse -Force
Remove-Item $zipPath -Force

Write-Host "Done!" -ForegroundColor Green
