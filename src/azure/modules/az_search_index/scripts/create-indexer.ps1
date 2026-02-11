<#
.SYNOPSIS
  Creates or updates an Azure Search indexer via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $IndexerName,
  [Parameter(Mandatory)] [string] $DataSourceName,
  [Parameter(Mandatory)] [string] $SkillsetName,
  [Parameter(Mandatory)] [string] $IndexName
)

$ErrorActionPreference = 'Stop'

$body = @{
  name            = $IndexerName
  dataSourceName  = $DataSourceName
  skillsetName    = $SkillsetName
  targetIndexName = $IndexName
  parameters = @{
    batchSize              = 1
    maxFailedItems         = -1
    maxFailedItemsPerBatch = 0
    configuration = @{
      allowSkillsetToReadFileData = $true
    }
  }
  fieldMappings = @(
    @{
      sourceFieldName = "metadata_storage_name"
      targetFieldName = "document_title"
    }
  )
  outputFieldMappings = @()
} | ConvertTo-Json -Depth 10

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/indexers/$($IndexerName)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated indexer: $IndexerName"
