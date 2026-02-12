# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

"""
DESCRIPTION:
    Given an AIProjectClient, this sample demonstrates how to use the synchronous
    `.connections` methods to enumerate the properties of all connections
    and get the properties of a connection by its name.

USAGE:
    To use this script and list the connections, they must be created securely in the portal.
    We need 2 connections:
    1. Azure Search Index connection:
    - Instructions:
        - Go to Foundry / Click your user logo / Project details / Add connection / Azure AI Search / Continue
        - Select the Azure Search resource
        - Auth Type: API Key
        - Click Connect
    > Note: Connecting the Azure Search to the project makes the Knowledge Base available in the "Knowledge" tab

    2. Torishima pump MCP server connection:
    - Instructions:
        - Go to Foundry / Click your user logo / Project details / Add connection / Select API Key / Continue
        - Create new connection:
        - Enter:
            - MCP server endpoint
            - X-API-Key secret value
            - Give it a DNS compatible name
            - Click Connect
        Result can be seen in "Connected resources" tab

    Once Connections are created for the project, this script will list them.

    python sample_connections.py

    Before running the sample:

    pip install "azure-ai-projects>=2.0.0b1" python-dotenv

    Set these environment variables with your own values:
    1) AZURE_AI_PROJECT_ENDPOINT - Required. The Azure AI Project endpoint, as found in the overview page of your
       Microsoft Foundry project.

REFERENCE:
    https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/connections/sample_connections.py

    https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/connections-add?view=foundry&preserve-view=true&tabs=foundry-portal
"""

import os
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import ConnectionType

load_dotenv()

endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
connection_name = os.environ["CONNECTION_NAME"]

with (
    DefaultAzureCredential() as credential,
    AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
):
    # [START connections_sample]
    print("List all connections:")
    for connection in project_client.connections.list():
        print(connection)

    # print("List all connections of a particular type:")
    # for connection in project_client.connections.list(
    #     connection_type=ConnectionType.AZURE_OPEN_AI,
    # ):
    #     print(connection)

    # print("Get the default connection of a particular type, without its credentials:")
    # connection = project_client.connections.get_default(
    #     connection_type=ConnectionType.AZURE_OPEN_AI
    # )
    # print(connection)

    # print("Get the default connection of a particular type, with its credentials:")
    # connection = project_client.connections.get_default(
    #     connection_type=ConnectionType.AZURE_OPEN_AI, include_credentials=True
    # )
    # print(connection)

    # print(f"Get the connection named `{connection_name}`, without its credentials:")
    # connection = project_client.connections.get(connection_name)
    # print(connection)

    # print(f"Get the connection named `{connection_name}`, with its credentials:")
    # connection = project_client.connections.get(
    #     connection_name, include_credentials=True
    # )
    # print(connection)
    # [END connection_sample]
