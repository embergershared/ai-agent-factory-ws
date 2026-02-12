"""
List and display Azure Foundry deployed models in a Foundry project.

Requires the following environment variables (set in .env or shell):
    FOUNDRY_PROJECT_ENDPOINT         - The Foundry project endpoint URL.

Prerequisites:
    Authenticate with ``az login`` before running this script.

Inspired from:
    https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/deployments/sample_deployments.py

Note:
There are no Foundry SDK object to deploy models.
They can be deployed using: Azure portal / Azure CLI / Bicep / terraform / maybe? Azure REST API.
"""

from collections.abc import Sequence
from urllib.parse import urlparse

import logging
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ModelDeployment
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

logger = logging.getLogger(__name__)


def _print_deployment_details(deployment: ModelDeployment | object) -> None:
    """Print the key properties of a *ModelDeployment*."""
    if not isinstance(deployment, ModelDeployment):
        print(f"  {deployment}")
        return
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


def _print_deployments_table(deployments: Sequence[object], endpoint: str) -> None:
    """Print deployments as a formatted table.

    Columns: Name, Model, Version, Publisher, Chat, Deployment Type.
    """
    parsed = urlparse(endpoint)
    resource_name = parsed.hostname.split(".")[0] if parsed.hostname else ""
    project_name = parsed.path.rstrip("/").rsplit("/", 1)[-1] if parsed.path else ""

    print(f"Foundry resource: {resource_name}")
    print(f"Foundry  project: {project_name}\n")

    headers = ("Name", "Model", "Version", "Publisher", "Chat", "Type (capacity)")
    rows: list[tuple[str, str, str, str, str, str]] = []

    for d in deployments:
        if isinstance(d, ModelDeployment):
            # Capabilities is a dict; extract chat_completion flag
            caps = d.capabilities or {}
            chat = caps.get("chat_completion", "")

            # SKU is a dict with name and capacity
            sku = d.sku or {}
            sku_name = sku.get("name", "")
            sku_capacity = sku.get("capacity", "")
            sku_str = f"{sku_name} ({sku_capacity})" if sku_name else ""

            rows.append(
                (
                    d.name or "",
                    d.model_name or "",
                    d.model_version or "",
                    d.model_publisher or "",
                    chat,
                    sku_str,
                )
            )
        else:
            rows.append((str(d), "", "", "", "", ""))

    # Sort by publisher (ascending), then name (ascending)
    rows.sort(key=lambda r: (r[3].lower(), r[0].lower()))

    # Calculate column widths (header width is the minimum)
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    # Format header + separator + rows
    fmt = "  ".join(f"{{:<{w}}}" for w in widths)
    sep = "  ".join("-" * w for w in widths)

    print(fmt.format(*headers))
    print(sep)
    for row in rows:
        print(fmt.format(*row))


def _list_all_deployments(client: AIProjectClient, endpoint: str) -> None:
    """List every deployment in the project."""
    deployments = list(client.deployments.list())
    print(f"All deployments ({len(deployments)}):\n")
    _print_deployments_table(deployments, endpoint)


def _load_config() -> str:
    """Load and validate the required environment variable.

    Returns:
        The Foundry project endpoint URL.
    """
    load_dotenv()

    foundry_project_endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")

    if not foundry_project_endpoint:
        logger.error("FOUNDRY_PROJECT_ENDPOINT is not set.")
        sys.exit(1)

    return foundry_project_endpoint


def main() -> None:
    """Enumerate and inspect deployments in a Foundry project."""
    endpoint = _load_config()

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
    ):
        _list_all_deployments(project_client, endpoint)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    main()
