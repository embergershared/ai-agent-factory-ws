// =============================================================================
// Azure Bastion Host for VM connectivity
// Uses Azure Verified Modules (AVM) pattern
// =============================================================================

@description('Azure region for the resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {
  project: 'pumps-agent'
  purpose: 'bastion-connectivity'
}

@description('Subscription ID where the VNet is located')
param networkSubscriptionId string = subscription().subscriptionId

@description('Resource group name where the VNet is located')
param networkResourceGroupName string = resourceGroup().name

@description('Name of the Virtual Network')
param vnetName string

@description('Name of the Bastion Host (defaults to vnetName-bastion)')
param bastionName string = 'bastion-${vnetName}'

@description('Name of the Public IP for Bastion (defaults to vnetName-bastion-pip)')
param bastionPublicIpName string = 'bastion-pip-${vnetName}'

@description('SKU of the Bastion Host')
@allowed(['Basic', 'Standard', 'Premium'])
param bastionSku string = 'Standard'

@description('Number of scale units for the Bastion Host (2-50, only for Standard/Premium SKU)')
@minValue(2)
@maxValue(50)
param scaleUnits int = 2

@description('Enable file copy - requires Standard or Premium SKU')
param enableFileCopy bool = true

@description('Optional. Availability zones for the Bastion (1, 2, 3). Defaults to no zones.')
param availabilityZones int[] = []

// =============================================================================
// Resources - Azure Bastion Host
// =============================================================================

@description('Azure Bastion Host for secure VM connectivity')
module bastionHost 'br/public:avm/res/network/bastion-host:0.8.2' = {
  name: 'deploy-bastion-${uniqueString(bastionName)}'
  params: {
    name: bastionName
    location: location
    tags: tags
    skuName: bastionSku
    scaleUnits: scaleUnits
    virtualNetworkResourceId: '/subscriptions/${networkSubscriptionId}/resourceGroups/${networkResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
    // Public IP is created automatically by the module using publicIPAddressObject
    publicIPAddressObject: union(
      {
        name: bastionPublicIpName
        skuName: 'Standard'
        skuTier: 'Regional'
        publicIPAllocationMethod: 'Static'
      },
      !empty(availabilityZones) ? { availabilityZones: availabilityZones } : {}
    )
    enableFileCopy: bastionSku != 'Basic' ? enableFileCopy : false
    disableCopyPaste: false
    enableShareableLink: false
    enableKerberos: false
    enableIpConnect: false
    availabilityZones: !empty(availabilityZones) ? availabilityZones : null
  }
}

// =============================================================================
// Outputs
// =============================================================================

@description('The resource ID of the Bastion Host')
output bastionResourceId string = bastionHost.outputs.resourceId

@description('The name of the Bastion Host')
output bastionName string = bastionHost.outputs.name

@description('The IP configuration of the Bastion subnet')
output ipConfiguration object = bastionHost.outputs.ipConfAzureBastionSubnet

@description('The location of the Bastion Host')
output location string = bastionHost.outputs.location
