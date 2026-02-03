// =============================================================================
// Storage Account and Blob Container for PDF Manuals
// Private endpoint configuration following AI Landing Zone patterns
// =============================================================================

@description('Azure region for the resources')
param location string = resourceGroup().location

@description('Base name for the resources')
param baseName string = 'pumpsmanuals'

@description('Environment name (dev, test, prod)')
@allowed(['dev', 'test', 'prod', 'demo'])
param environment string = 'dev'

@description('Tags to apply to all resources')
param tags object = {
  project: 'pumps-agent'
  purpose: 'pdf-manuals-storage'
}

@description('Enable or disable public network access. Defaults to Disabled for security.')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Disabled'

@description('Optional. Public IP address to allow access from (e.g., your public IP). Only used when publicNetworkAccess is Enabled.')
param allowedPublicIpAddress string = ''

@description('Subscription ID where the VNet and DNS zones are located')
param networkSubscriptionId string = subscription().subscriptionId

@description('Resource group name where the VNet is located')
param networkResourceGroupName string = resourceGroup().name

@description('Name of the Virtual Network containing the private endpoint subnet')
param vnetName string

@description('Name of the subnet for private endpoints')
param privateEndpointSubnetName string

@description('Resource group name where the private DNS zones are located (defaults to networkResourceGroupName)')
param dnsZoneResourceGroupName string = networkResourceGroupName

@description('Optional. Custom name for the storage account. If not provided, a name will be generated.')
param storageAccountName string = ''

@description('Name of the blob container for manuals')
param containerName string = 'pumps-manuals'

// =============================================================================
// Variables
// =============================================================================

// Storage account name must be 3-24 characters, lowercase letters and numbers only
var effectiveStorageAccountName = !empty(storageAccountName)
  ? storageAccountName
  : toLower(take('st${baseName}${environment}${uniqueString(resourceGroup().id)}', 24))

// Construct resource IDs from parameters
var privateEndpointSubnetResourceId = '/subscriptions/${networkSubscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${privateEndpointSubnetName}'
var blobPrivateDnsZoneResourceId = '/subscriptions/${networkSubscriptionId}/resourceGroups/${dnsZoneResourceGroupName}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.${az.environment().suffixes.storage}'
var deployPrivateEndpoint = !empty(vnetName) && !empty(privateEndpointSubnetName)

// =============================================================================
// Resources
// =============================================================================

@description('Storage account for PDF manuals - private access only')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: effectiveStorageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: !empty(allowedPublicIpAddress)
        ? [
            {
              value: allowedPublicIpAddress
              action: 'Allow'
            }
          ]
        : []
      virtualNetworkRules: []
    }
  }
}

@description('Blob service for the storage account')
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

@description('Blob container for PDF manuals')
resource manualsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'pdf-manuals'
    }
  }
}

// =============================================================================
// Private Endpoint for Blob Storage
// =============================================================================

@description('Private endpoint for blob storage')
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (deployPrivateEndpoint) {
  name: 'pe-st-${storageAccountName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: 'blobConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

@description('Private DNS zone group for blob private endpoint')
resource blobDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (deployPrivateEndpoint && !empty(blobPrivateDnsZoneResourceId)) {
  parent: blobPrivateEndpoint
  name: 'blobDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blobARecord'
        properties: {
          privateDnsZoneId: blobPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

// =============================================================================
// Outputs
// =============================================================================

@description('The name of the storage account')
output storageAccountName string = storageAccount.name

@description('The resource ID of the storage account')
output storageAccountId string = storageAccount.id

@description('The primary blob endpoint')
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('The name of the manuals container')
output containerName string = manualsContainer.name

@description('The full URL to the manuals container')
output containerUrl string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'

@description('The full URL to the folder within the container')
output folderUrl string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}/'

@description('The private endpoint resource ID (if deployed)')
output privateEndpointId string = deployPrivateEndpoint ? blobPrivateEndpoint.id : ''
