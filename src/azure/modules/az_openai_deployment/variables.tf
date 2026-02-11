###############################################################################
# Module: Azure OpenAI Deployment - Variables
###############################################################################

variable "deployment_name" {
  description = "The name of the deployment (e.g. 'text-embedding-ada-002', 'gpt-4o')."
  type        = string
}

variable "cognitive_account_id" {
  description = "The resource ID of the Azure OpenAI / Cognitive Services account."
  type        = string
}

# Models formats and names can be retrieved with: az cognitiveservices model list -l <location> --query "[].{Format: model.format, Name: model.name}" -o table
variable "model_format" {
  type        = string
  description = "The format of the model (e.g. 'OpenAI', 'xAI', 'Anthropic', 'Mistral AI')."
  default     = "OpenAI"
}

variable "model_name" {
  description = "The name of the OpenAI model to deploy (e.g. 'text-embedding-ada-002', 'gpt-4o'). Get the list with the command: az cognitiveservices model list -l <location>."
  type        = string
  default     = "gpt-5.2"
}

variable "model_version" {
  description = "The version of the model to deploy (e.g. '2', '2024-11-20')."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "The SKU name for the deployment (e.g. 'Standard', 'GlobalStandard')."
  type        = string
  default     = "Standard"
}

variable "sku_capacity" {
  description = "The capacity (TPM) for the deployment. Set to null for Standard SKUs."
  type        = number
  default     = null
}
