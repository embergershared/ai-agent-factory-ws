<#
.SYNOPSIS
  Creates or updates an Azure Search data source via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $Name,
  [Parameter(Mandatory)] [string] $ConnectionString,
  [Parameter(Mandatory)] [string] $ContainerName
)

$ErrorActionPreference = 'Stop'

$container = @{ name = $ContainerName }

$body = @{
  name        = $Name
  type        = "azureblob"
  credentials = @{
    connectionString = $ConnectionString
  }
  container   = $container
} | ConvertTo-Json -Depth 10

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/datasources/$($Name)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated datasource: $Name"
