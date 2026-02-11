"""List, inspect, and create Azure AI model deployments in a Foundry project.

Requires the following environment variables (set in .env or shell):
    FOUNDRY_PROJECT_ENDPOINT         – The Foundry project endpoint URL.
    FOUNDRY_OPENAI_ENDPOINT          – The Foundry OpenAI endpoint URL.
    FOUNDRY_API_ENDPOINT             – The Foundry API endpoint URL.
    MODEL_PUBLISHER                  – (optional) Publisher filter (default: Microsoft).
    MODEL_NAME                       – (optional) Model name filter (default: Phi-4).

    For deployment creation (via CognitiveServicesManagementClient):
    AZURE_SUBSCRIPTION_ID            – Azure subscription ID.
    AZURE_RESOURCE_GROUP             – Resource group containing the OpenAI account.
    AZURE_OPENAI_ACCOUNT_NAME        – Name of the Azure OpenAI / Cognitive Services account.

Inspired from:
    https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/
    azure-ai-projects/samples/deployments/sample_deployments.py
"""

from __future__ import annotations

import logging
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ModelDeployment
from azure.core.credentials import TokenCredential
from azure.identity import DefaultAzureCredential
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from azure.mgmt.cognitiveservices.models import (
    Deployment,
    DeploymentModel,
    DeploymentProperties,
    Sku,
)
from dotenv import load_dotenv

logger = logging.getLogger(__name__)


def _print_deployment_details(deployment: ModelDeployment) -> None:
    """Print the key properties of a *ModelDeployment*."""
    details = (
        f"  Type:             {deployment.type}\n"
        f"  Name:             {deployment.name}\n"
        f"  Model Name:       {deployment.model_name}\n"
        f"  Model Version:    {deployment.model_version}\n"
        f"  Model Publisher:  {deployment.model_publisher}\n"
        f"  Capabilities:     {deployment.capabilities}\n"
        f"  SKU:              {deployment.sku}\n"
        f"  Connection Name:  {deployment.connection_name}"
    )
    print(details)


def _list_all_deployments(client: AIProjectClient) -> None:
    """List every deployment in the project."""
    deployments = client.deployments.list()
    print("List all deployments:")
    for deployment in deployments:
        # print(f"  - {deployment}")
        _print_deployment_details(deployment)
        print()


def _list_by_publisher(client: AIProjectClient, publisher: str) -> None:
    """List deployments filtered by model publisher."""
    print(f"\nList deployments by publisher '{publisher}':")
    for deployment in client.deployments.list(model_publisher=publisher):
        print(f"  - {deployment}")


def _list_by_model(client: AIProjectClient, model_name: str) -> None:
    """List deployments filtered by model name."""
    print(f"\nList deployments of model '{model_name}':")
    for deployment in client.deployments.list(model_name=model_name):
        print(f"  - {deployment}")


def _get_deployment(client: AIProjectClient, name: str) -> None:
    """Retrieve a single deployment by name and print its details."""
    print(f"\nGet deployment '{name}':")
    deployment = client.deployments.get(name)

    if isinstance(deployment, ModelDeployment):
        _print_deployment_details(deployment)
    else:
        print(f"  {deployment}")


def _create_deployment(
    credential: TokenCredential,
    subscription_id: str,
    resource_group: str,
    account_name: str,
    deployment_name: str = "gpt-5.2",
    *,
    model_format: str = "OpenAI",
    model_name: str,
    model_version: str,
    sku_name: str = "Standard",
    sku_capacity: int = 1,
) -> None:
    """Create (or update) an OpenAI model deployment.

    Uses ``CognitiveServicesManagementClient`` because
    ``AIProjectClient.deployments`` only supports read operations.

    Args:
        credential:      Azure credential for authentication.
        subscription_id: Azure subscription ID.
        resource_group:  Resource group of the OpenAI account.
        account_name:    Name of the Azure OpenAI / Cognitive Services account.
        deployment_name: Desired deployment name (e.g. 'gpt-4.1').
        model_format:    Model format (default: 'OpenAI').
        model_name:      Model name (e.g. 'gpt-4.1', 'text-embedding-ada-002').
        model_version:   Model version string (e.g. '1', '2').
        sku_name:        SKU tier (default: 'Standard').
        sku_capacity:    Token-rate capacity (default: 1).
    """
    print(
        f"\nCreating deployment '{deployment_name}' "
        f"(model={model_name} v{model_version}, sku={sku_name}) ..."
    )

    with CognitiveServicesManagementClient(
        credential=credential,
        subscription_id=subscription_id,
    ) as cogsvc_client:
        deployment_config = Deployment(
            properties=DeploymentProperties(
                model=DeploymentModel(
                    format=model_format,
                    name=model_name,
                    version=model_version,
                ),
            ),
            sku=Sku(name=sku_name, capacity=sku_capacity),
        )

        poller = cogsvc_client.deployments.begin_create_or_update(
            resource_group_name=resource_group,
            account_name=account_name,
            deployment_name=deployment_name,
            deployment=deployment_config,
        )
        result = poller.result()  # blocks until deployment completes
        print(f"  ✓ Deployment '{result.name}' created successfully.")


def _load_config() -> tuple[str, str, str, str, str, str, str, str]:
    """Load and validate required environment variables.

    Returns:
        A tuple of (foundry_project_endpoint, foundry_openai_endpoint,
        foundry_api_endpoint, model_publisher, model_name,
        subscription_id, resource_group, account_name).
    """
    load_dotenv()

    # Foundry endpoints
    foundry_project_endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    foundry_openai_endpoint = os.getenv("FOUNDRY_OPENAI_ENDPOINT")
    foundry_api_endpoint = os.getenv("FOUNDRY_API_ENDPOINT")

    if not foundry_project_endpoint:
        logger.error("FOUNDRY_PROJECT_ENDPOINT is not set.")
        sys.exit(1)
    if not foundry_openai_endpoint:
        logger.error("FOUNDRY_OPENAI_ENDPOINT is not set.")
        sys.exit(1)
    if not foundry_api_endpoint:
        logger.error("FOUNDRY_API_ENDPOINT is not set.")
        sys.exit(1)

    model_publisher = os.getenv("MODEL_PUBLISHER", "Microsoft")
    model_name = os.getenv("MODEL_NAME", "Phi-4")

    # Required for deployment creation via CognitiveServicesManagementClient
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID", "")
    resource_group = os.getenv("AZURE_RESOURCE_GROUP", "")
    account_name = os.getenv("AZURE_OPENAI_ACCOUNT_NAME", "")

    return (
        foundry_project_endpoint,
        foundry_openai_endpoint,
        foundry_api_endpoint,
        model_publisher,
        model_name,
        subscription_id,
        resource_group,
        account_name,
    )


def main() -> None:
    """Enumerate, inspect, and create deployments in a Foundry project."""
    (
        foundry_project_endpoint,
        foundry_openai_endpoint,
        foundry_api_endpoint,
        model_publisher,
        model_name,
        subscription_id,
        resource_group,
        account_name,
    ) = _load_config()

    print("Foundry endpoints:")
    print(f"  Project endpoint: {foundry_project_endpoint}")
    print(f"  OpenAI endpoint:  {foundry_openai_endpoint}")
    print(f"  API endpoint:     {foundry_api_endpoint}")

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(
            endpoint=foundry_project_endpoint,
            credential=credential,
        ) as project_client,
    ):
        _list_all_deployments(project_client)
        # _list_by_publisher(project_client, model_publisher)
        # _list_by_model(project_client, model_name)
        # _get_deployment(project_client, deployment_name)

        # _create_deployment(
        #     credential,
        #     subscription_id,
        #     resource_group,
        #     account_name,
        #     deployment_name="gpt-4.1",
        #     model_name="gpt-4.1",
        #     model_version="2",
        #     sku_name="Standard",
        #     sku_capacity=1,
        # )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    main()
