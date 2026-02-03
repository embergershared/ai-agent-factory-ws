# AI Agent Factory Workshop - Azure deployments

## Overview

This section of the repo deploys the Azure resources to demonstrate the AI Agent Factory capabilities using Azure services.

## Deployment steps

1. **Prerequisites**:
   - Ensure you have an active Azure subscription.
   - Install the Azure CLI on your local machine.
   - Install Terraform on your local machine.

2. **Deploy the AI Landing Zone**:

   ```pwsh
   # 1. Move im the root folder to receive the rendered deployment code

   # 2. Set environment variables
   $env:AZURE_LOCATION = "swedencentral"
   $env:AZURE_RESOURCE_GROUP = "rg-swc-ai-agent-factory-ws"
   $env:AZURE_SUBSCRIPTION_ID = "XXXX-YYYY-ZZZZ-AAAA-BBBBCCCCDDDD"  # replace with your subscription ID

   # 2. Authenticate to Azure
   az login
   azd auth login

    # 3. Create a new Resource Group
    az group create --name $env:AZURE_RESOURCE_GROUP --location $env:AZURE_LOCATION --tags SecurityControl=Ignore
      
   # 4. Initialize the AI Landing Zones template
   azd init -t Azure/AI-Landing-Zones -e ai-agent-factory-demos

   # 5. Tune deployment parameters
   # by editing  the bicep/infra/main.bicepparam file

   # 6. Deploy the AI Landing Zone
   azd provision
   ```

## 3. Deploy the AI Agent Factory Workshop resources

### a. Storage account with private endpoint for pumps manuals

```pwsh
# 1. Create a Storage Account and Blob container for the pumps manuals

# Set the parameters for the deployment (uses environment variables set in step 2)
$SUBSCRIPTION_ID = $env:AZURE_SUBSCRIPTION_ID
$RESOURCE_GROUP = $env:AZURE_RESOURCE_GROUP
$BICEP_PATH = ".\pumps-agent-resources\manuals"
$PUBLIC_IP = (Invoke-WebRequest -Uri 'https://api.ipify.org').Content
$VNET_NAME = "vnet-kfdflmm4bt3m"
$STORAGE_ACCOUNT_NAME = "stpumpsmanuals$(Get-Random -Maximum 9999)"

# Deploy the storage account with private endpoint
# networkSubscriptionId and networkResourceGroupName come from environment variables
az deployment group create `
  --resource-group $RESOURCE_GROUP `
  --template-file "$BICEP_PATH\main.bicep" `
  --parameters "$BICEP_PATH\main.bicepparam" `
  --parameters networkSubscriptionId=$SUBSCRIPTION_ID `
              networkResourceGroupName=$RESOURCE_GROUP `
              allowedPublicIpAddress=$PUBLIC_IP `
              vnetName=$VNET_NAME `
              storageAccountName=$STORAGE_ACCOUNT_NAME

# Get the storage account name from the deployment output
$STORAGE_ACCOUNT = (az deployment group show `
  --resource-group $RESOURCE_GROUP `
  --name main `
  --query properties.outputs.storageAccountName.value -o tsv)

$CONTAINER_NAME = (az deployment group show `
  --resource-group $RESOURCE_GROUP `
  --name main `
  --query properties.outputs.containerName.value -o tsv)

# 2. Upload the pumps manuals to the storage account using azcopy

# Ensure you're logged in with azcopy (uses Azure AD auth)
.\azcopy login

# Upload all PDF files from the local manuals folder to the blob container
$LOCAL_MANUALS_PATH = ".\pumps-agent-resources\manuals\pdfs\*"
$BLOB_CONTAINER_URL = "https://$STORAGE_ACCOUNT.blob.core.windows.net/$CONTAINER_NAME"

.\azcopy copy $LOCAL_MANUALS_PATH $BLOB_CONTAINER_URL --recursive

# Verify the upload
az storage blob list `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER_NAME `
  --auth-mode login `
  --output table

# Lock the Storage account networking settings to prevent public access
az storage account update `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --public-network-access Disabled
```

### b. Azure Bastion Host for VM connectivity

```pwsh
# Deploy Azure Bastion Host to enable secure VM connectivity
# Note: The VNet must have an AzureBastionSubnet with at least /26 CIDR block

# Set the parameters for the deployment (uses environment variables set in step 2)
# Note: AZURE_SUBSCRIPTION_ID and AZURE_RESOURCE_GROUP must be set as environment variables
$BICEP_PATH = ".\pumps-agent-resources\bastion"

# Deploy the Bastion Host
az deployment group create `
  --resource-group $env:AZURE_RESOURCE_GROUP `
  --subscription $env:AZURE_SUBSCRIPTION_ID `
  --template-file "$BICEP_PATH\main.bicep" `
  --parameters "$BICEP_PATH\main.bicepparam"

# Verify the Bastion Host deployment
az network bastion show `
  --name "$VNET_NAME-bastion" `
  --resource-group $RESOURCE_GROUP `
  --output table
```

## References

https://azure.github.io/AI-Landing-Zones/bicep/how-to-use/