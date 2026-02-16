# =============================================================================
# Build & Push MCP Pump Switch Docker Image to Azure Container Registry
# =============================================================================
# Prerequisites:
#   - Docker Desktop running
#   - Azure CLI installed and logged in (az login)
#
# Usage:
#   .\build-and-push-to-acr.ps1 [-AcrName "acrswcs3aimsfoundrydemo02yim"]
#   .\build-and-push-to-acr.ps1 -Tag "v2"
# =============================================================================

param(
  [Parameter(Mandatory = $false)]
  [string]$AcrName = "acrswcs3aimsfoundrydemo02yim",

  [Parameter(Mandatory = $false)]
  [string]$ImageName = "mcp-pump-switch",

  [Parameter(Mandatory = $false)]
  [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

# Resolve the directory where this script (and the Dockerfile) lives
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$AcrLoginServer = "$AcrName.azurecr.io"
$FullImageTag = "${AcrLoginServer}/${ImageName}:${Tag}"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build & Push to ACR"                      -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ACR:       $AcrLoginServer"
Write-Host "Image:     $ImageName"
Write-Host "Tag:       $Tag"
Write-Host "Full tag:  $FullImageTag"
Write-Host ""

# ── 1. Login to ACR ─────────────────────────────────────────────────────────
Write-Host "[1/3] Logging in to ACR..." -ForegroundColor Yellow
az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) { throw "ACR login failed" }
Write-Host "  ✓ Logged in" -ForegroundColor Green

# ── 2. Build the Docker image ───────────────────────────────────────────────
Write-Host ""
Write-Host "[2/3] Building Docker image..." -ForegroundColor Yellow
docker build -t $FullImageTag $ScriptDir
if ($LASTEXITCODE -ne 0) { throw "Docker build failed" }
Write-Host "  ✓ Image built: $FullImageTag" -ForegroundColor Green

# ── 3. Push to ACR ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/3] Pushing image to ACR..." -ForegroundColor Yellow
docker push $FullImageTag
if ($LASTEXITCODE -ne 0) { throw "Docker push failed" }
Write-Host "  ✓ Image pushed: $FullImageTag" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Done! Image available at:"                -ForegroundColor Cyan
Write-Host "  $FullImageTag"                          -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
