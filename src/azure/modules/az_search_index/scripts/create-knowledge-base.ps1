<#
.SYNOPSIS
  Creates or updates an Azure Search knowledge base via REST API.
#>
param(
  [Parameter(Mandatory)] [string] $SearchUrl,
  [Parameter(Mandatory)] [string] $ApiKey,
  [Parameter(Mandatory)] [string] $ApiVersion,
  [Parameter(Mandatory)] [string] $Name,
  [Parameter(Mandatory)] [string] $KnowledgeSourceName,
  [Parameter(Mandatory)] [string] $AiServicesOpenAiUrl,
  [Parameter(Mandatory)] [string] $ChatDeploymentName,
  [Parameter(Mandatory)] [string] $ChatModelName
)

$ErrorActionPreference = 'Stop'

$body = @{
  name                  = $Name
  description           = ""
  retrievalInstructions = ""
  answerInstructions    = ""
  outputMode            = "extractiveData"
  knowledgeSources      = @( @{ name = $KnowledgeSourceName } )
  models = @(
    @{
      kind                  = "azureOpenAI"
      azureOpenAIParameters = @{
        resourceUri  = $AiServicesOpenAiUrl
        deploymentId = $ChatDeploymentName
        modelName    = $ChatModelName
      }
    }
  )
  retrievalReasoningEffort = @{ kind = "minimal" }
} | ConvertTo-Json -Depth 10

$headers = @{
  "Content-Type" = "application/json"
  "api-key"      = $ApiKey
}

$uri = "$SearchUrl/knowledgebases/$($Name)?api-version=$ApiVersion"
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body | Out-Null
Write-Host "Created/updated knowledge base: $Name"
