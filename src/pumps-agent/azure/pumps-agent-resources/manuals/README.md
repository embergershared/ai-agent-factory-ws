# PDF Manuals Storage

This folder contains Bicep templates to deploy an Azure Storage Account with a blob container for storing PDF pump manuals, configured with **private endpoints** following the AI Landing Zone patterns.

## Resources Created

- **Storage Account** (`Microsoft.Storage/storageAccounts`)
  - StorageV2 kind
  - Standard_LRS replication
  - Hot access tier
  - TLS 1.2 minimum
  - HTTPS only
  - **No public blob access**
  - **Public network access disabled**
  - **Shared Key access disabled** (Entra ID auth only)
  - Network ACLs deny all public traffic

- **Blob Container** (`manuals`)
  - Private access level
  - For storing PDF pump manuals

- **Private Endpoint** (for blob storage)
  - Connects to the private endpoint subnet
  - DNS zone group for automatic DNS registration

## Prerequisites

Before deploying, ensure you have:

1. An existing Virtual Network with a subnet for private endpoints
2. A private DNS zone for blob storage (`privatelink.blob.core.windows.net`) linked to the VNet
3. The resource IDs for both the subnet and DNS zone

These are typically created as part of the AI Landing Zone deployment.

## Deployment

### Prerequisites

- Azure CLI installed
- Logged into Azure (`az login`)
- Resource group created

### Update Parameters

Edit `main.bicepparam` and replace the placeholder values:

```bicep
// Replace with your actual subnet resource ID
param privateEndpointSubnetResourceId = '/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/virtualNetworks/<vnet-name>/subnets/<pe-subnet-name>'

// Replace with your actual private DNS zone resource ID
param blobPrivateDnsZoneResourceId = '/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
```

### Deploy using Azure CLI

```bash
# Set variables
RESOURCE_GROUP="rg-swc-ai-agent-ws"

# Deploy using the bicepparam file
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters main.bicepparam
```

### Deploy with inline parameters

```bash
PE_SUBNET_ID="/subscriptions/.../subnets/pe-subnet"
DNS_ZONE_ID="/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters \
    location=swedencentral \
    environment=prod \
    baseName=pumpsmanuals \
    privateEndpointSubnetResourceId=$PE_SUBNET_ID \
    blobPrivateDnsZoneResourceId=$DNS_ZONE_ID
```

## Outputs

After deployment, the following outputs are available:

| Output                 | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `storageAccountName`   | The name of the storage account                |
| `storageAccountId`     | The resource ID of the storage account         |
| `blobEndpoint`         | The primary blob endpoint URL                  |
| `containerName`        | The name of the manuals container              |
| `containerUrl`         | The full URL to the manuals container          |
| `privateEndpointId`    | The resource ID of the private endpoint        |

## Uploading PDF Manuals

Since the storage account uses private endpoints and disables shared key access, you must:

1. Be connected to the VNet (or use a jump VM/bastion)
2. Use Azure AD authentication

```bash
# Get the storage account name from deployment output
STORAGE_ACCOUNT=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name main \
  --query properties.outputs.storageAccountName.value -o tsv)

# Upload a PDF file using Azure AD auth (requires being on the VNet)
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name manuals \
  --name "pump-manual.pdf" \
  --file "./pump-manual.pdf" \
  --auth-mode login
```

## Security Features

This deployment follows security best practices:

- ✅ Public network access disabled
- ✅ Shared Key access disabled (Entra ID only)
- ✅ Private endpoint for secure VNet access
- ✅ Network ACLs deny all by default
- ✅ TLS 1.2 minimum
- ✅ HTTPS only
- ✅ No public blob access
