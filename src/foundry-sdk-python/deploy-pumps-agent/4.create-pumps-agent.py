"""Create the Foundry pumps-agent with MCP tools and Foundry IQ knowledge base.

The agent is created with two MCP tools:
  1. The custom MCP pump-switch server (for valve operations).
  2. The Foundry IQ knowledge base (exposed as an MCP endpoint by Azure
     AI Search over the knowledge base created in Foundry IQ).

Requires the following environment variables (set in .env or shell):
    FOUNDRY_PROJECT_ENDPOINT         - The Foundry project endpoint URL.
    PUMPS_AGENT_NAME                 - Agent name (identifier).
    PUMPS_AGENT_DISPLAY_NAME         - Agent display name (used in metadata welcomeMessage).
    PUMPS_AGENT_MODEL                - Model deployment name (e.g. 'gpt-5.2').
    PUMPS_AGENT_DESCRIPTION          - Agent description.
    PUMPS_AGENT_INSTRUCTIONS         - System instructions for the agent.
    PUMPS_AGENT_STARTER_PROMPTS      - Newline-separated starter prompts for the UI.
    MCP_PROJECT_CONNECTION_ID        - The MCP pump-switch connection Azure Resource ID.
    KB_MCP_SERVER_URL                - The knowledge base MCP endpoint URL.
    KB_PROJECT_CONNECTION_ID         - The knowledge base project connection name.

Prerequisites:
    - Model used must be deployed.
    - MCP pump-switch server connection must be created in the portal (Custom keys).
    - Foundry IQ knowledge base must exist (created via the Foundry IQ UI
      over the Azure AI Search index).  The knowledge base connection is
      auto-created when the KB is built in Foundry IQ.

Inspired from:
    https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/tools/sample_agent_mcp_with_project_connection.py
    https://learn.microsoft.com/en-us/python/api/overview/azure/ai-projects-readme?view=azure-python
"""

import json
import logging
import os
import sys

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    MCPTool,
    PromptAgentDefinition,
)
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

logger = logging.getLogger(__name__)


def _load_config() -> tuple[str, str, str, str, str, str, str, str, str, str]:
    """Load and validate the required environment variables.

    Returns:
        A tuple of (endpoint, agent_name, display_name, model, description,
        instructions, starter_prompts, mcp_connection_id, kb_mcp_server_url,
        kb_project_connection_id).
    """
    load_dotenv()

    foundry_project_endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    agent_name = os.getenv("PUMPS_AGENT_NAME")
    agent_display_name = os.getenv("PUMPS_AGENT_DISPLAY_NAME")
    agent_model = os.getenv("PUMPS_AGENT_MODEL")
    agent_description = os.getenv("PUMPS_AGENT_DESCRIPTION")
    agent_instructions = os.getenv("PUMPS_AGENT_INSTRUCTIONS")
    agent_starter_prompts = os.getenv("PUMPS_AGENT_STARTER_PROMPTS")
    mcp_connection_id = os.getenv("MCP_PROJECT_CONNECTION_ID")
    kb_mcp_server_url = os.getenv("KB_MCP_SERVER_URL")
    kb_project_connection_id = os.getenv("KB_PROJECT_CONNECTION_ID")

    missing = [
        name
        for name, val in (
            ("FOUNDRY_PROJECT_ENDPOINT", foundry_project_endpoint),
            ("PUMPS_AGENT_NAME", agent_name),
            ("PUMPS_AGENT_DISPLAY_NAME", agent_display_name),
            ("PUMPS_AGENT_MODEL", agent_model),
            ("PUMPS_AGENT_DESCRIPTION", agent_description),
            ("PUMPS_AGENT_INSTRUCTIONS", agent_instructions),
            ("PUMPS_AGENT_STARTER_PROMPTS", agent_starter_prompts),
            ("MCP_PROJECT_CONNECTION_ID", mcp_connection_id),
            ("KB_MCP_SERVER_URL", kb_mcp_server_url),
            ("KB_PROJECT_CONNECTION_ID", kb_project_connection_id),
        )
        if not val
    ]
    if missing:
        for name in missing:
            logger.error("%s is not set.", name)
        sys.exit(1)

    # All validated as non-empty above; assert for the type checker.
    assert foundry_project_endpoint
    assert agent_name
    assert agent_display_name
    assert agent_model
    assert agent_description
    assert agent_instructions
    assert agent_starter_prompts
    assert mcp_connection_id
    assert kb_mcp_server_url
    assert kb_project_connection_id

    return (
        foundry_project_endpoint,
        agent_name,
        agent_display_name,
        agent_model,
        agent_description,
        agent_instructions,
        agent_starter_prompts,
        mcp_connection_id,
        kb_mcp_server_url,
        kb_project_connection_id,
    )


def main() -> None:
    """Create the pumps-agent."""
    (
        endpoint,
        agent_name,
        agent_display_name,
        agent_model,
        agent_description,
        agent_instructions,
        agent_starter_prompts,
        mcp_connection_id,
        kb_mcp_server_url,
        kb_project_connection_id,
    ) = _load_config()

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
    ):
        print(f"Connected to project: {endpoint}")

        # --- MCP tool 1: Torishima pump switch actions ---
        mcp_pump_switch = MCPTool(
            server_label="torishima-pump-switch",
            server_url="https://aca-app-mcp-pump-switch.livelymushroom-0d14d900.swedencentral.azurecontainerapps.io/mcp",
            require_approval="never",
            project_connection_id=mcp_connection_id,
        )

        # --- MCP tool 2: Foundry IQ knowledge base (pumps manuals) ---
        mcp_knowledge_base = MCPTool(
            server_label=kb_project_connection_id,
            server_url=kb_mcp_server_url,
            project_connection_id=kb_project_connection_id,
        )

        # --- Agent metadata (welcome message + starter prompts) ---
        # starterPrompts uses \n as separator between prompts.
        metadata = {
            "welcomeMessage": agent_display_name,
            "starterPrompts": agent_starter_prompts,
        }

        # --- Create the agent ---
        agent = project_client.agents.create(
            name=agent_name,
            description=agent_description,
            metadata=metadata,
            definition=PromptAgentDefinition(
                model=agent_model,
                instructions=agent_instructions,
                tools=[mcp_pump_switch, mcp_knowledge_base],
            ),
        )
        print(f"Created agent '{agent_display_name}', agent ID: {agent.id}")

        # --- Retrieve the agent details (JSON) ---
        agent_details = project_client.agents.get(agent_name=agent_name)
        print(f"\nAgent details for '{agent_details.name}':")
        print(json.dumps(dict(agent_details), indent=2, default=str))

        # --- Retrieve the latest version details ---
        latest = agent_details.versions.latest
        defn = dict(latest.definition)
        print(f"\nLatest version: {latest.version}  (created {latest.created_at})")
        print(f"  Model      : {defn.get('model')}")
        print(f"  Tools      : {[t['type'] for t in defn.get('tools', [])]}")
        print(f"  Description: {latest.description}")

        # --- List all agents in the project ---
        print("\nAll agents in the project:")
        for a in project_client.agents.list():
            v = a.versions.latest
            print(f"  - {a.name} (id={a.id}, version={v.version})")


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING, format="%(levelname)s: %(message)s")
    main()
