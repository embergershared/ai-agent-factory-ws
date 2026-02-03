using 'main.bicep'

// =============================================================================
// Azure Bastion Host Parameters
// =============================================================================

// VNet where Bastion will be deployed (must have an AzureBastionSubnet)
param vnetName = 'vnet-kfdflmm4bt3m'

// Bastion configuration
param bastionName = 'bastion-vnet-kfdflmm4bt3m'
param bastionPublicIpName = 'bastion-pip-vnet-kfdflmm4bt3m'
param bastionSku = 'Standard'
param scaleUnits = 2
param enableFileCopy = true

// Optional: Availability zones for the Bastion (uncomment to enable zone redundancy)
// param availabilityZones = [1, 2, 3]

// Tags
param tags = {
  project: 'ai-agent-factory'
  purpose: 'bastion-connectivity'
  environment: 'workshop'
}
