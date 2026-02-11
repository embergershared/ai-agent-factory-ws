<#
.SYNOPSIS
  Creates or updates an Azure Search skillset via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $SkillsetName,
  [Parameter(Mandatory)] [string] $IndexName,
  [Parameter(Mandatory)] [string] $CognitiveServicesUrl,
  [Parameter(Mandatory)] [string] $StorageConnectionString
)

$ErrorActionPreference = 'Stop'

$body = @{
  name   = $SkillsetName
  skills = @(
    @{
      "@odata.type" = "#Microsoft.Skills.Util.DocumentExtractionSkill"
      name          = "#1"
      context       = "/document"
      parsingMode   = "default"
      dataToExtract = "contentAndMetadata"
      inputs  = @( @{ name = "file_data"; source = "/document/file_data"; inputs = @() } )
      outputs = @(
        @{ name = "content";           targetName = "extracted_content" }
        @{ name = "normalized_images"; targetName = "normalized_images" }
      )
      configuration = @{
        imageAction                             = "generateNormalizedImages"
        "normalizedImageMaxWidth@odata.type"    = "#Int64"
        normalizedImageMaxWidth                 = 2000
        "normalizedImageMaxHeight@odata.type"   = "#Int64"
        normalizedImageMaxHeight                = 2000
      }
    }
    @{
      "@odata.type"       = "#Microsoft.Skills.Text.SplitSkill"
      name                = "#2"
      context             = "/document"
      defaultLanguageCode = "en"
      textSplitMode       = "pages"
      maximumPageLength   = 2000
      pageOverlapLength   = 200
      maximumPagesToTake  = 0
      unit                = "characters"
      inputs  = @( @{ name = "text"; source = "/document/extracted_content"; inputs = @() } )
      outputs = @( @{ name = "textItems"; targetName = "pages" } )
    }
    @{
      "@odata.type" = "#Microsoft.Skills.Vision.VectorizeSkill"
      name          = "#3"
      context       = "/document/pages/*"
      modelVersion  = "2023-04-15"
      inputs  = @( @{ name = "text"; source = "/document/pages/*"; inputs = @() } )
      outputs = @( @{ name = "vector"; targetName = "text_vector" } )
    }
    @{
      "@odata.type" = "#Microsoft.Skills.Vision.VectorizeSkill"
      name          = "#4"
      context       = "/document/normalized_images/*"
      modelVersion  = "2023-04-15"
      inputs  = @( @{ name = "image"; source = "/document/normalized_images/*"; inputs = @() } )
      outputs = @( @{ name = "vector"; targetName = "image_vector" } )
    }
    @{
      "@odata.type" = "#Microsoft.Skills.Util.ShaperSkill"
      name          = "#5"
      context       = "/document/normalized_images/*"
      inputs = @(
        @{ name = "normalized_images"; source = "/document/normalized_images/*"; inputs = @() }
        @{ name = "imagePath"; source = "='vectorized-images/'+`$(/document/normalized_images/*/imagePath)"; inputs = @() }
        @{
          name          = "locationMetadata"
          sourceContext = "/document/normalized_images/*"
          inputs = @(
            @{ name = "pageNumber";       source = "/document/normalized_images/*/pageNumber";      inputs = @() }
            @{ name = "boundingPolygons"; source = "/document/normalized_images/*/boundingPolygon"; inputs = @() }
          )
        }
      )
      outputs = @( @{ name = "output"; targetName = "new_normalized_images" } )
    }
  )
  cognitiveServices = @{
    "@odata.type" = "#Microsoft.Azure.Search.AIServicesByIdentity"
    subdomainUrl  = $CognitiveServicesUrl
  }
  knowledgeStore = @{
    storageConnectionString = $StorageConnectionString
    projections = @(
      @{
        tables  = @()
        objects = @()
        files   = @(
          @{
            storageContainer = "vectorized-images"
            generatedKeyName = "vectorized-imagesKey"
            source           = "/document/normalized_images/*"
            inputs           = @()
          }
        )
      }
    )
    parameters = @{ synthesizeGeneratedKeyName = $true }
  }
  indexProjections = @{
    selectors = @(
      @{
        targetIndexName    = $IndexName
        parentKeyFieldName = "text_document_id"
        sourceContext      = "/document/pages/*"
        mappings = @(
          @{ name = "content_text";      source = "/document/pages/*";             inputs = @() }
          @{ name = "content_embedding"; source = "/document/pages/*/text_vector"; inputs = @() }
          @{ name = "document_title";    source = "/document/document_title";      inputs = @() }
        )
      }
      @{
        targetIndexName    = $IndexName
        parentKeyFieldName = "image_document_id"
        sourceContext      = "/document/normalized_images/*"
        mappings = @(
          @{ name = "content_embedding"; source = "/document/normalized_images/*/image_vector";                          inputs = @() }
          @{ name = "content_path";      source = "/document/normalized_images/*/new_normalized_images/imagePath";       inputs = @() }
          @{ name = "document_title";    source = "/document/document_title";                                            inputs = @() }
          @{ name = "locationMetadata";  source = "/document/normalized_images/*/new_normalized_images/locationMetadata"; inputs = @() }
        )
      }
    )
    parameters = @{ projectionMode = "skipIndexingParentDocuments" }
  }
} | ConvertTo-Json -Depth 30

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/skillsets/$($SkillsetName)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated skillset: $SkillsetName"
