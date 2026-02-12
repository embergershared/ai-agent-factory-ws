###############################################################################
# Module: Azure Foundry Deployment - Variables
###############################################################################

variable "deployment_name" {
  description = "The name of the deployment (e.g. 'Phi-4-mini-instruct', 'DeepSeek-V3')."
  type        = string
}

variable "cognitive_account_id" {
  description = "The resource ID of the AI Services / Foundry account."
  type        = string
}

# Model formats and names can be retrieved with: az cognitiveservices model list -l <location> --query "[].{Format: model.format, Name: model.name}" -o table
variable "model_format" {
  description = "The format of the model (e.g. 'Microsoft', 'DeepSeek', 'xAI', 'Anthropic')."
  type        = string
  default     = "Microsoft"
}

variable "model_name" {
  description = "The name of the model to deploy (e.g. 'Phi-4-mini-instruct'). Get the list with: az cognitiveservices model list -l <location>."
  type        = string
}

variable "model_version" {
  description = "The version of the model to deploy (e.g. '1')."
  type        = string
  default     = null
}

variable "sku_name" {
  description = "The SKU name for the deployment (e.g. 'GlobalStandard', 'Standard')."
  type        = string
  default     = "GlobalStandard"
}

variable "sku_capacity" {
  description = "The capacity (TPM) for the deployment."
  type        = number
  default     = 1
}
