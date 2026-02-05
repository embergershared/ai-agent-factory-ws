# Enable Semantic ranker in AI Search

import os
import subprocess
import sys

import requests
import json

from azure.core.credentials import AzureKeyCredential
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (  # type: ignore[import-untyped]
    AzureBlobKnowledgeSource,
    AzureBlobKnowledgeSourceParameters,
    AzureOpenAIVectorizerParameters,
    KnowledgeBaseAzureOpenAIModel,
    KnowledgeSourceAzureOpenAIVectorizer,
    KnowledgeSourceContentExtractionMode,
    KnowledgeSourceIngestionParameters,
)
from dotenv import load_dotenv


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
    description: str,
    blob_connection_string: str,
    blob_container_name: str,
    aoai_endpoint: str,
    aoai_api_key: str,
    aoai_embedding_deployment: str,
    aoai_chat_deployment: str,
    folder_path: str | None = None,
) -> None:
    """Create a blob knowledge source in Azure AI Search.

    Args:
        ai_search_url: The Azure AI Search service URL (e.g., https://xxx.search.windows.net).
        api_key: The Azure AI Search API key.
        knowledge_source_name: The name for the knowledge source.
        description: A description of the knowledge source.
        blob_connection_string: The connection string for the blob storage.
        blob_container_name: The name of the blob container.
        aoai_endpoint: The Azure OpenAI endpoint URL.
        aoai_api_key: The Azure OpenAI API key.
        aoai_embedding_deployment: The Azure OpenAI embedding model deployment name.
        aoai_chat_deployment: The Azure OpenAI chat completion model deployment name.
        folder_path: Optional folder path within the container.
    """
    # Construct the payload for the knowledge source
    payload = {
        "name": knowledge_source_name,
        "description": description,
        "kind": "azureblob",
        "azureBlobParameters": {
            "connectionString": blob_connection_string,
            "containerName": blob_container_name,
            "folderPath": folder_path,
            "isAdlsGen2": False,
            "ingestionParameters": {
                "disableImageVerbalization": False,
                "chatCompletionModel": {
                    "azureOpenAiParameters": {
                        "resourceUri": aoai_endpoint,
                        "apiKey": aoai_api_key,
                        "deploymentId": aoai_chat_deployment,
                        "modelName": None,
                    }
                },
                "embeddingModel": {
                    "azureOpenAiParameters": {
                        "resourceUri": aoai_endpoint,
                        "apiKey": aoai_api_key,
                        "deploymentId": aoai_embedding_deployment,
                        "modelName": None,
                    }
                },
                "contentExtractionMode": "minimal",
                "ingestionSchedule": None,
                "ingestionPermissionOptions": None,
            },
        },
    }

    # Remove None values from folderPath if not provided
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


def main() -> None:
    """Initialize and validate the AI Project client connection."""
    # Load environment variables from .env file
    load_dotenv()

    # Get all required environment variables at the start
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
    resource_group = os.getenv("AZURE_RESOURCE_GROUP")
    ai_search_name = os.getenv("AI_SEARCH_NAME")
    api_key = os.getenv("AI_SEARCH_KEY")

    # Validate required environment variables
    missing_vars = []
    if not subscription_id:
        missing_vars.append("AZURE_SUBSCRIPTION_ID")
    if not resource_group:
        missing_vars.append("AZURE_RESOURCE_GROUP")
    if not ai_search_name:
        missing_vars.append("AI_SEARCH_NAME")
    if not api_key:
        missing_vars.append("AI_SEARCH_KEY")

    if missing_vars:
        print(
            f"✗ Error: Missing required environment variables: {', '.join(missing_vars)}"
        )
        print("  Please ensure these are set in your .env file.")
        sys.exit(1)

    # Type narrowing after validation
    assert subscription_id is not None
    assert resource_group is not None
    assert ai_search_name is not None
    assert api_key is not None

    # try:
    #     enable_search_semantic_ranker(
    #         subscription_id=subscription_id,
    #         resource_group=resource_group,
    #         ai_search_name=ai_search_name,
    #     )
    # except Exception as e:
    #     print(f"✗ Failed to enable semantic search: {e}")
    #     sys.exit(1)

    try:
        list_knowledge_sources(ai_search_name=ai_search_name, api_key=api_key)
    except Exception as e:
        print(f"✗ Failed to list knowledge sources: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
