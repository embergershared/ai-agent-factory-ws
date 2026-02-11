###############################################################################
# Module: Azure Search Index Pipeline - Variables
###############################################################################

variable "search_service_name" {
  description = "Name of the Azure AI Search service."
  type        = string
}

variable "search_api_key" {
  description = "Admin API key for the Azure AI Search service."
  type        = string
  sensitive   = true
}

variable "search_api_version" {
  description = "Azure Search REST API version for index/datasource/skillset/indexer operations."
  type        = string
  default     = "2025-05-01-preview"
}

variable "knowledge_api_version" {
  description = "Azure Search REST API version for knowledge source/base operations."
  type        = string
  default     = "2025-11-01-preview"
}

variable "cognitive_services_name" {
  description = "Name of the Cognitive Services (multi-service) account."
  type        = string
}

variable "ai_services_name" {
  description = "Name of the AI Services account (for OpenAI endpoint in knowledge base)."
  type        = string
}

variable "index_prefix" {
  description = "Name prefix for all Search index resources."
  type        = string
  default     = "multimodal-rag-pumps-manuals"
}

variable "storage_account_resource_id" {
  description = "Full Azure resource ID of the storage account."
  type        = string
}

variable "blob_container_name" {
  description = "Name of the blob container."
  type        = string
}

variable "chat_deployment_name" {
  description = "Azure OpenAI chat completion deployment name (for knowledge base)."
  type        = string
  default     = "gpt-4.1"
}

variable "chat_model_name" {
  description = "Azure OpenAI chat completion model name (for knowledge base)."
  type        = string
  default     = "gpt-4.1"
}
