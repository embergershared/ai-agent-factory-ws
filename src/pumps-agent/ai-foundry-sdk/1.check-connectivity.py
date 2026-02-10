"""Check Azure AI Foundry connectivity and authentication."""

import os
import sys

from azure.identity import DefaultAzureCredential
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from dotenv import load_dotenv


def main() -> None:
    """Test authentication by instantiating the Cognitive Services client."""
    # Load environment variables from .env file
    load_dotenv()

    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
    if not subscription_id:
        print("✗ Error: AZURE_SUBSCRIPTION_ID not found in environment variables.")
        sys.exit(1)

    try:
        credential = DefaultAzureCredential()
        client = CognitiveServicesManagementClient(credential, subscription_id)
        # Verify the client works by listing accounts (limited to 1)
        list(client.accounts.list())[:1]
        print("✓ Authentication successful! Ready to create a project.")
    except Exception as e:
        print(f"✗ Authentication failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
