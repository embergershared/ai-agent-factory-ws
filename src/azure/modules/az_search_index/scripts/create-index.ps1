<#
.SYNOPSIS
  Creates or updates an Azure Search index via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $IndexName,
  [Parameter(Mandatory)] [string] $CognitiveServicesUrl
)

$ErrorActionPreference = 'Stop'

$body = @{
  name   = $IndexName
  fields = @(
    @{ name = "content_id";        type = "Edm.String"; key = $true;  searchable = $true;  filterable = $false; retrievable = $true; stored = $true; sortable = $true;  facetable = $false; analyzer = "keyword"; synonymMaps = @() }
    @{ name = "text_document_id";  type = "Edm.String"; key = $false; searchable = $false; filterable = $true;  retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
    @{ name = "document_title";    type = "Edm.String"; key = $false; searchable = $true;  filterable = $false; retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
    @{ name = "image_document_id"; type = "Edm.String"; key = $false; searchable = $false; filterable = $true;  retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
    @{ name = "content_text";      type = "Edm.String"; key = $false; searchable = $true;  filterable = $false; retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
    @{
      name                = "content_embedding"
      type                = "Collection(Edm.Single)"
      key                 = $false
      searchable          = $true
      filterable          = $false
      retrievable         = $true
      stored              = $true
      sortable            = $false
      facetable           = $false
      dimensions          = 1024
      vectorSearchProfile = "$IndexName-aiServicesVision-text-profile"
      synonymMaps         = @()
    }
    @{ name = "content_path";      type = "Edm.String"; key = $false; searchable = $true;  filterable = $false; retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
    @{
      name   = "locationMetadata"
      type   = "Edm.ComplexType"
      fields = @(
        @{ name = "pageNumber";       type = "Edm.Int32";  searchable = $false; filterable = $true;  retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
        @{ name = "boundingPolygons"; type = "Edm.String"; searchable = $false; filterable = $false; retrievable = $true; stored = $true; sortable = $false; facetable = $false; synonymMaps = @() }
      )
    }
  )
  semantic = @{
    defaultConfiguration = "$IndexName-semantic-configuration"
    configurations       = @(
      @{
        name             = "$IndexName-semantic-configuration"
        prioritizedFields = @{
          titleField                = @{ fieldName = "document_title" }
          prioritizedContentFields  = @( @{ fieldName = "content_text" } )
          prioritizedKeywordsFields = @()
        }
      }
    )
  }
  vectorSearch = @{
    algorithms = @(
      @{
        name           = "$IndexName-algorithm"
        kind           = "hnsw"
        hnswParameters = @{ metric = "cosine"; m = 4; efConstruction = 400; efSearch = 500 }
      }
    )
    profiles = @(
      @{
        name       = "$IndexName-aiServicesVision-text-profile"
        algorithm  = "$IndexName-algorithm"
        vectorizer = "$IndexName-aiServicesVision-text-vectorizer"
      }
    )
    vectorizers = @(
      @{
        name                      = "$IndexName-aiServicesVision-text-vectorizer"
        kind                      = "aiServicesVision"
        aiServicesVisionParameters = @{
          modelVersion = "2023-04-15"
          resourceUri  = $CognitiveServicesUrl
        }
      }
    )
    compressions = @()
  }
} | ConvertTo-Json -Depth 20

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/indexes/$($IndexName)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated index: $IndexName"
