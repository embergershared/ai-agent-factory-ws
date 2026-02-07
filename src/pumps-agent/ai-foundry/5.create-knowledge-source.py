# Create the Knowledge Base for the pumps Manuals

import os
import subprocess
import sys

import requests
import json

from azure.core.credentials import AzureKeyCredential
from azure.search.documents.indexes import SearchIndexClient

# from azure.search.documents.indexes.models import (  # type: ignore[import-untyped]
#     AzureBlobKnowledgeSource,
#     AzureBlobKnowledgeSourceParameters,
#     AzureOpenAIVectorizerParameters,
#     KnowledgeBaseAzureOpenAIModel,
#     KnowledgeSourceAzureOpenAIVectorizer,
#     KnowledgeSourceContentExtractionMode,
#     KnowledgeSourceIngestionParameters,
# )
from dotenv import load_dotenv


def get_resource_principal_id(resource_id: str) -> str:
    """Get the principal ID of a resource's system-assigned managed identity.

    Args:
        resource_id: The full Azure resource ID.

    Returns:
        The principal ID (object ID) of the resource's managed identity.

    Raises:
        SystemExit: If the command fails or the principal ID cannot be retrieved.
    """
    cmd = [
        "az",
        "resource",
        "show",
        "--ids",
        resource_id,
        "--query",
        "identity.principalId",
        "-o",
        "tsv",
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, shell=True)

    if result.returncode != 0:
        print(f"✗ Failed to get principal ID for resource: {result.stderr}")
        sys.exit(1)

    principal_id = result.stdout.strip()
    if not principal_id:
        print(f"✗ No managed identity found for resource: {resource_id}")
        sys.exit(1)

    print(f"✓ Retrieved principal ID: {principal_id}")
    return principal_id


def create_role_assignment(
    assignee: str,
    role: str,
    scope: str,
) -> None:
    """Create a role assignment using Azure CLI.

    Args:
        assignee: The principal ID (object ID) of the user, group, or service principal.
        role: The role name or role definition ID to assign.
        scope: The scope at which the role assignment applies (e.g., resource ID).
    """
    cmd = [
        "az",
        "role",
        "assignment",
        "create",
        "--assignee",
        assignee,
        "--role",
        role,
        "--scope",
        scope,
    ]

    print(f"✓ Creating role assignment: {role} for {assignee}")
    result = subprocess.run(cmd, capture_output=True, text=True, shell=True)

    if result.returncode != 0:
        print(f"✗ Failed to create role assignment: {result.stderr}")
        sys.exit(1)

    print(f"✓ Role assignment '{role}' created successfully")


def enable_search_semantic_ranker(
    subscription_id: str,
    resource_group: str,
    ai_search_name: str,
) -> None:
    """Enable semantic ranker on an Azure AI Search service.

    Args:
        subscription_id: The Azure subscription ID.
        resource_group: The Azure resource group name.
        ai_search_name: The AI Search service name.
    """
    resource_id = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/Microsoft.Search/searchServices/{ai_search_name}"
    )

    cmd = [
        "az",
        "resource",
        "update",
        "--ids",
        resource_id,
        "--set",
        "properties.semanticSearch=standard",
    ]

    print(f"✓ Enabling semantic search on: {ai_search_name}")
    result = subprocess.run(cmd, capture_output=True, text=True, shell=True)

    if result.returncode != 0:
        print(f"✗ Failed to enable semantic search: {result.stderr}")
        sys.exit(1)

    print("✓ Semantic search enabled successfully")


def list_knowledge_sources(ai_search_name: str, api_key: str) -> None:
    # List knowledge sources by name and type

    endpoint = f"https://{ai_search_name}.search.windows.net/knowledgesources"
    params = {"api-version": "2025-11-01-preview", "$select": "name, kind"}
    headers = {"api-key": f"{api_key}"}

    response = requests.get(endpoint, params=params, headers=headers)
    print(json.dumps(response.json(), indent=2))


def create_blob_knowledge_source(
    ai_search_url: str,
    api_key: str,
    knowledge_source_name: str,
    storage_account_resource_id: str,
    blob_container_name: str,
    aoai_endpoint: str,
    aoai_embedding_deployment: str,
    aoai_embedding_model_name: str,
    aoai_chat_deployment: str,
    aoai_chat_model_name: str,
    ai_services_uri: str,
    description: str | None = None,
    folder_path: str | None = None,
    ingestion_interval: str = "P1D",
) -> None:
    """Create a blob knowledge source in Azure AI Search using managed identity.

    Args:
        ai_search_url: The Azure AI Search service URL (e.g., https://xxx.search.windows.net).
        api_key: The Azure AI Search API key.
        knowledge_source_name: The name for the knowledge source.
        storage_account_resource_id: The full Azure resource ID of the storage account.
        blob_container_name: The name of the blob container.
        aoai_endpoint: The Azure OpenAI endpoint URL.
        aoai_embedding_deployment: The Azure OpenAI embedding model deployment name.
        aoai_embedding_model_name: The Azure OpenAI embedding model name.
        aoai_chat_deployment: The Azure OpenAI chat completion model deployment name.
        aoai_chat_model_name: The Azure OpenAI chat completion model name.
        ai_services_uri: The Azure AI Services (Cognitive Services) URI.
        description: Optional description of the knowledge source.
        folder_path: Optional folder path within the container.
        ingestion_interval: The ingestion schedule interval (default: "P1D" for daily).
    """
    # Use ResourceId format for managed identity authentication
    connection_string = f"ResourceId={storage_account_resource_id};"

    # Construct the payload for the knowledge source (matching Azure API schema)
    payload: dict = {
        "name": knowledge_source_name,
        "kind": "azureBlob",
        "description": description,
        "azureBlobParameters": {
            "connectionString": connection_string,
            "containerName": blob_container_name,
            "folderPath": folder_path,
            "ingestionParameters": {
                "disableImageVerbalization": False,
                "ingestionPermissionOptions": [],
                "contentExtractionMode": "standard",
                "identity": None,
                "embeddingModel": {
                    "kind": "azureOpenAI",
                    "azureOpenAIParameters": {
                        "resourceUri": aoai_endpoint,
                        "deploymentId": aoai_embedding_deployment,
                        "modelName": aoai_embedding_model_name,
                    },
                },
                "chatCompletionModel": {
                    "kind": "azureOpenAI",
                    "azureOpenAIParameters": {
                        "resourceUri": aoai_endpoint,
                        "deploymentId": aoai_chat_deployment,
                        "modelName": aoai_chat_model_name,
                    },
                },
                "ingestionSchedule": {
                    "interval": ingestion_interval,
                },
                "aiServices": {
                    "uri": ai_services_uri,
                },
            },
        },
    }

    # Remove folderPath if not provided
    if folder_path is None:
        del payload["azureBlobParameters"]["folderPath"]

    endpoint = f"{ai_search_url}/knowledgesources/{knowledge_source_name}?api-version=2025-11-01-preview"
    headers = {
        "Content-Type": "application/json",
        "api-key": api_key,
    }

    response = requests.put(endpoint, headers=headers, data=json.dumps(payload))
    if response.status_code in (200, 201):
        print(
            f"✓ Knowledge source '{knowledge_source_name}' created or updated successfully."
        )
    else:
        print(f"✗ Failed to create or update knowledge source: {response.text}")
        sys.exit(1)


def create_knowledge_base(
    ai_search_url: str,
    api_key: str,
    knowledge_base_name: str,
    knowledge_source_names: list[str],
    aoai_endpoint: str,
    aoai_chat_deployment: str,
    aoai_chat_model_name: str,
    description: str | None = None,
    retrieval_instructions: str | None = None,
    answer_instructions: str | None = None,
    output_mode: str = "answerSynthesis",
    retrieval_reasoning_effort: str = "medium",
) -> None:
    """Create a knowledge base in Azure AI Search.

    Args:
        ai_search_url: The Azure AI Search service URL (e.g., https://xxx.search.windows.net).
        api_key: The Azure AI Search API key.
        knowledge_base_name: The name for the knowledge base.
        knowledge_source_names: List of knowledge source names to include.
        aoai_endpoint: The Azure OpenAI endpoint URL.
        aoai_chat_deployment: The Azure OpenAI chat completion model deployment name.
        aoai_chat_model_name: The Azure OpenAI chat completion model name.
        description: Optional description of the knowledge base.
        retrieval_instructions: Optional instructions for retrieval.
        answer_instructions: Optional instructions for answer synthesis.
        output_mode: Output mode (default: "answerSynthesis").
        retrieval_reasoning_effort: Reasoning effort level (default: "medium").
    """
    # Build knowledge sources list
    knowledge_sources = [{"name": name} for name in knowledge_source_names]

    # Construct the payload for the knowledge base
    payload: dict = {
        "name": knowledge_base_name,
        "description": description or "",
        "retrievalInstructions": retrieval_instructions or "",
        "answerInstructions": answer_instructions,
        "outputMode": output_mode,
        "knowledgeSources": knowledge_sources,
        "models": [
            {
                "kind": "azureOpenAI",
                "azureOpenAIParameters": {
                    "resourceUri": aoai_endpoint,
                    "deploymentId": aoai_chat_deployment,
                    "modelName": aoai_chat_model_name,
                },
            }
        ],
        "retrievalReasoningEffort": {
            "kind": retrieval_reasoning_effort,
        },
    }

    endpoint = f"{ai_search_url}/knowledgebases/{knowledge_base_name}?api-version=2025-11-01-preview"
    headers = {
        "Content-Type": "application/json",
        "api-key": api_key,
    }

    response = requests.put(endpoint, headers=headers, data=json.dumps(payload))
    if response.status_code in (200, 201):
        print(
            f"✓ Knowledge base '{knowledge_base_name}' created or updated successfully."
        )
    else:
        print(f"✗ Failed to create or update knowledge base: {response.text}")
        sys.exit(1)


def load_and_validate_env_vars() -> dict[str, str]:
    """Load and validate all required environment variables.

    Returns:
        A dictionary containing all validated environment variables.

    Raises:
        SystemExit: If any required environment variables are missing.
    """
    # Load environment variables from .env file
    load_dotenv()

    # Define required environment variables
    required_vars = [
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_RESOURCE_GROUP",
        "AZ_SEARCH_NAME",
        "AZ_SEARCH_KEY",
        "AZ_FOUNDRY_RESOURCE_NAME",
        "AZ_FOUNDRY_PUMPS_PROJECT_NAME",
        "STORAGE_ACCOUNT_NAME",
        "STORAGE_ACCOUNT_CONTAINER_NAME",
        "AOAI_ENDPOINT",
        "AOAI_EMBEDDING_DEPLOYMENT",
        "AOAI_EMBEDDING_MODEL_NAME",
        "AOAI_CHAT_DEPLOYMENT",
        "AOAI_CHAT_MODEL_NAME",
        "AI_SERVICES_URI",
    ]

    # Get all required environment variables
    env_vars: dict[str, str | None] = {var: os.getenv(var) for var in required_vars}

    # Validate required environment variables
    missing_vars = [var for var, value in env_vars.items() if not value]

    if missing_vars:
        print(
            f"✗ Error: Missing required environment variables: {', '.join(missing_vars)}"
        )
        print("  Please ensure these are set in your .env file.")
        sys.exit(1)

    # Type narrowing: all values are now guaranteed to be non-None strings
    return {var: value for var, value in env_vars.items() if value is not None}


def setup_role_assignments(
    foundry_principal_id: str,
    foundry_resource_id: str,
    az_search_principal_id: str,
    az_search_resource_id: str,
    storage_account_resource_id: str,
) -> None:
    """Set up required role assignments for Azure AI Search knowledge sources.

    This function creates the necessary RBAC role assignments to allow:
    - Azure AI Foundry to access Azure Search
    - Azure Search to access Azure AI Foundry (Cognitive Services)
    - Azure Search to access the blob storage account

    Args:
        foundry_principal_id: The principal ID of the Azure AI Foundry resource.
        foundry_resource_id: The full resource ID of the Azure AI Foundry resource.
        az_search_principal_id: The principal ID of the Azure Search resource.
        az_search_resource_id: The full resource ID of the Azure Search resource.
        storage_account_resource_id: The full resource ID of the storage account.
    """
    print("\n=== Setting up role assignments ===")

    # a. Foundry resource "Search Index Data Contributor" and "Search Service Contributor" roles to Azure Search
    create_role_assignment(
        assignee=foundry_principal_id,
        role="Search Index Data Contributor",
        scope=az_search_resource_id,
    )
    create_role_assignment(
        assignee=foundry_principal_id,
        role="Search Service Contributor",
        scope=az_search_resource_id,
    )

    # b. Azure Search "Cognitive Services User" role on Foundry resource (not project)
    create_role_assignment(
        assignee=az_search_principal_id,
        role="Cognitive Services User",
        scope=foundry_resource_id,
    )

    # c. Azure Search "Storage Blob Data Contributor" role on the blob storage account (needs to write diagrams)
    create_role_assignment(
        assignee=az_search_principal_id,
        role="Storage Blob Data Contributor",
        scope=storage_account_resource_id,
    )

    print("=== Role assignments complete ===\n")


def main() -> None:
    """Initialize and validate the AI Project client connection."""
    # Load and validate environment variables
    env = load_and_validate_env_vars()

    # Extract variables for easier access
    subscription_id = env["AZURE_SUBSCRIPTION_ID"]
    resource_group = env["AZURE_RESOURCE_GROUP"]
    azure_search_service_name = env["AZ_SEARCH_NAME"]
    azure_search_api_key = env["AZ_SEARCH_KEY"]
    foundry_resource_name = env["AZ_FOUNDRY_RESOURCE_NAME"]
    foundry_project_name = env["AZ_FOUNDRY_PUMPS_PROJECT_NAME"]
    storage_account_name = env["STORAGE_ACCOUNT_NAME"]

    # Setting resources IDs and getting managed identity principal IDs
    foundry_resource_id = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/Microsoft.CognitiveServices/accounts/{foundry_resource_name}"
    )
    az_search_resource_id = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/Microsoft.Search/searchServices/{azure_search_service_name}"
    )
    storage_account_resource_id = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/Microsoft.Storage/storageAccounts/{storage_account_name}"
    )

    foundry_principal_id = get_resource_principal_id(foundry_resource_id)
    az_search_principal_id = get_resource_principal_id(az_search_resource_id)

    # 1. Set the required role assignments
    setup_role_assignments(
        foundry_principal_id=foundry_principal_id,
        foundry_resource_id=foundry_resource_id,
        az_search_principal_id=az_search_principal_id,
        az_search_resource_id=az_search_resource_id,
        storage_account_resource_id=storage_account_resource_id,
    )

    # 2. Enable Semantic ranker in Azure Search
    try:
        enable_search_semantic_ranker(
            subscription_id=subscription_id,
            resource_group=resource_group,
            ai_search_name=azure_search_service_name,
        )
    except Exception as e:
        print(f"✗ Failed to enable semantic search: {e}")
        sys.exit(1)

    # 3. Create the blob knowledge source in Azure Search for the pumps manuals
    knowledge_source_name = "ks-python-created"
    create_blob_knowledge_source(
        knowledge_source_name=knowledge_source_name,
        description="Knowledge source created through python script",
        ai_search_url=f"https://{azure_search_service_name}.search.windows.net",
        api_key=azure_search_api_key,
        storage_account_resource_id=storage_account_resource_id,
        blob_container_name=env["STORAGE_ACCOUNT_CONTAINER_NAME"],
        aoai_endpoint=env["AOAI_ENDPOINT"],
        aoai_embedding_deployment=env["AOAI_EMBEDDING_DEPLOYMENT"],
        aoai_embedding_model_name=env["AOAI_EMBEDDING_MODEL_NAME"],
        aoai_chat_deployment=env["AOAI_CHAT_DEPLOYMENT"],
        aoai_chat_model_name=env["AOAI_CHAT_MODEL_NAME"],
        ai_services_uri=env["AI_SERVICES_URI"],
    )

    # 4. Create the knowledge base in Azure Search (can add other knowledge sources later)
    create_knowledge_base(
        knowledge_base_name="kb-python-created",
        description="Knowledge base created through python script",
        ai_search_url=f"https://{azure_search_service_name}.search.windows.net",
        api_key=azure_search_api_key,
        knowledge_source_names=[knowledge_source_name],
        aoai_endpoint=env["AOAI_ENDPOINT"],
        aoai_chat_deployment=env["AOAI_CHAT_DEPLOYMENT"],
        aoai_chat_model_name=env["AOAI_CHAT_MODEL_NAME"],
    )

    # 5. Connect Foundry IQ to Azure Search (knowledge base will sync)
    # Done manually through the Azure AI Foundry IQ UI, by selecting the Azure Search instance.
    # After that, all Knowledge Bases and Knowledge Sources created in Azure Search are automatically available in Foundry IQ.


if __name__ == "__main__":
    main()
