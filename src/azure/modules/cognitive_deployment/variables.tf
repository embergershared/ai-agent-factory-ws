###############################################################################
# Module: Cognitive Deployment - Variables
###############################################################################

variable "name" {
  description = "The name of the model deployment (e.g. 'gpt-4o', 'text-embedding-ada-002')."
  type        = string
}

variable "cognitive_account_id" {
  description = "The resource ID of the Cognitive Services account to deploy the model into."
  type        = string
}

variable "model_format" {
  description = "The format/provider of the model (e.g. 'OpenAI')."
  type        = string
  default     = "OpenAI"
}

variable "model_name" {
  description = "The name of the model to deploy (e.g. 'gpt-4o', 'text-embedding-ada-002')."
  type        = string
}

variable "model_version" {
  description = "The version of the model to deploy (e.g. '2024-11-20')."
  type        = string
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
