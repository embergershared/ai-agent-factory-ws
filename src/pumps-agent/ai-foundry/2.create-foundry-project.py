"""Connect to an Azure AI Foundry project."""

import os
import sys

from azure.ai.projects import AIProjectClient  # type: ignore[import-untyped]
from azure.identity import DefaultAzureCredential
from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
from dotenv import load_dotenv


def create_cognitive_services_client(
    subscription_id: str,
) -> CognitiveServicesManagementClient:
    """Create a Cognitive Services Management client.

    Args:
        subscription_id: The Azure subscription ID.

    Returns:
        An authenticated CognitiveServicesManagementClient instance.
    """
    return CognitiveServicesManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id=subscription_id,
        api_version="2025-12-01",
    )


def create_foundry_project(
    client: CognitiveServicesManagementClient,
    resource_group_name: str,
    foundry_resource_name: str,
    foundry_project_name: str,
    location: str,
) -> None:
    """Create a new Azure AI Foundry project.

    Args:
        client: The Cognitive Services Management client.
        resource_group_name: The Azure resource group name.
        foundry_resource_name: The AI Foundry account/resource name.
        foundry_project_name: The name for the new project.
        location: The Azure region for the project.
    """
    from azure.mgmt.cognitiveservices.models import Project, Identity, ProjectProperties

    project_properties = ProjectProperties(
        description="Pumps Agent Foundry project",
        project_type="Foundry",
    )
    project_params = Project(
        location=location,
        identity=Identity(type="SystemAssigned"),
        properties=project_properties,
    )

    poller = client.projects.begin_create(
        resource_group_name=resource_group_name,
        account_name=foundry_resource_name,
        project_name=foundry_project_name,
        project=project_params,
    )
    print(f"✓ Creating Foundry project: {foundry_project_name}")
    poller.wait()
    print(f"✓ Foundry project created successfully: {foundry_project_name}")


def connect_to_foundry_project(
    foundry_resource_name: str,
    project_name: str,
) -> AIProjectClient:
    """Connect to an existing Azure AI Foundry project.

    Args:
        foundry_resource_name: The AI Foundry resource name.
        project_name: The name of the project to connect to.

    Returns:
        An authenticated AIProjectClient instance.
    """
    endpoint = f"https://{foundry_resource_name}.services.ai.azure.com/api/projects/{project_name}"
    credential = DefaultAzureCredential()
    client = AIProjectClient(
        endpoint=endpoint,
        credential=credential,
    )
    print(f"✓ Connected to AI Foundry project: {project_name}")
    print(f"  Endpoint: {endpoint}")
    return client


def main() -> None:
    """Initialize and validate the AI Project client connection."""
    # Load environment variables from .env file
    load_dotenv()

    # Get all required environment variables at the start
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
    resource_group = os.getenv("AZURE_RESOURCE_GROUP")
    location = os.getenv("AZURE_LOCATION")
    azf_name = os.getenv("AZF_RESOURCE_NAME")
    project_name = os.getenv("AZF_PUMPS_PROJECT_NAME")

    # Validate all required environment variables
    missing_vars = []
    if not subscription_id:
        missing_vars.append("AZURE_SUBSCRIPTION_ID")
    if not resource_group:
        missing_vars.append("AZURE_RESOURCE_GROUP")
    if not location:
        missing_vars.append("AZURE_LOCATION")
    if not azf_name:
        missing_vars.append("AZF_RESOURCE_NAME")
    if not project_name:
        missing_vars.append("AZF_PUMPS_PROJECT_NAME")

    if missing_vars:
        print(
            f"✗ Error: Missing required environment variables: {', '.join(missing_vars)}"
        )
        print("  Please ensure these are set in your .env file.")
        sys.exit(1)

    # At this point, all variables are guaranteed to be non-None
    # Use assertions to help the type checker understand this
    assert subscription_id is not None
    assert resource_group is not None
    assert location is not None
    assert azf_name is not None
    assert project_name is not None

    try:
        cogsvc_client = create_cognitive_services_client(
            subscription_id=subscription_id,
        )

        create_foundry_project(
            client=cogsvc_client,
            resource_group_name=resource_group,
            foundry_resource_name=azf_name,
            foundry_project_name=project_name,
            location=location,
        )

    except Exception as e:
        print(f"✗ Failed to connect to AI Foundry project: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
