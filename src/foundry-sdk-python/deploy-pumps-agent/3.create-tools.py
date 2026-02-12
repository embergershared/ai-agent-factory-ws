"""Create tool connections for the Foundry agent.

TODO: Add tool creation logic (MCP tool, search tool connection, etc.).

Requires the following environment variables (set in .env or shell):
    FOUNDRY_PROJECT_ENDPOINT         - The Foundry project endpoint URL.

Prerequisites:
    Authenticate with ``az login`` before running this script.

Inspired from:
    https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/mcp_client/sample_mcp_tool_async.py
"""

import logging
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

logger = logging.getLogger(__name__)


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
    """Create tool connections for the Foundry agent."""
    endpoint = _load_config()

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
    ):
        print(f"Connected to project: {endpoint}")
        # TODO: Create tools here


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    main()
