<#
.SYNOPSIS
  Creates or updates an Azure Search knowledge source via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $Name,
  [Parameter(Mandatory)] [string] $IndexName
)

$ErrorActionPreference = 'Stop'

$body = @{
  name        = $Name
  kind        = "searchIndex"
  description = "Knowledge source that uses the Multimodal RAG index."
  searchIndexParameters = @{
    searchIndexName           = $IndexName
    semanticConfigurationName = $null
    sourceDataFields          = @()
    searchFields              = @()
  }
} | ConvertTo-Json -Depth 10

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/knowledgesources/$($Name)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated knowledge source: $Name"
