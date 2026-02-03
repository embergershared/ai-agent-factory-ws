using './main.bicep'

// =============================================================================
// Parameters for PDF Manuals Storage with Private Endpoints
// =============================================================================

param location = 'swedencentral'
param baseName = 'pumpsmanuals'
param environment = 'demo'
param tags = {
  project: 'pumps-agent'
  purpose: 'pdf-manuals-storage'
  SecurityControl: 'Ignore'
}

// =============================================================================
// Network Configuration - Update these values for your environment
// =============================================================================

// NOTE: networkSubscriptionId and networkResourceGroupName are passed via CLI
// from environment variables: $env:AZURE_SUBSCRIPTION_ID, $env:AZURE_RESOURCE_GROUP

// VNet and subnet names for private endpoints
param vnetName = 'vnet-kfdflmm4bt3m'
param privateEndpointSubnetName = 'pe-subnet'

// Resource group containing private DNS zones (defaults to networkResourceGroupName if not specified)
// Uncomment if DNS zones are in a different resource group
// param dnsZoneResourceGroupName = '<dns-zone-rg-name>'

// Public network access is Enabled to allow access from runner Public IP for uploads
param publicNetworkAccess = 'Enabled' // It is then changed to 'Disabled' to block all public access

// Your public IP address to allow access from (only used when publicNetworkAccess is 'Enabled')
// Get your IP with: (Invoke-WebRequest -Uri 'https://api.ipify.org').Content
param allowedPublicIpAddress = '<Your public IP>'

// =============================================================================
// Storage Configuration
// =============================================================================

// Custom storage account name (optional - leave empty to auto-generate)
// Must be 3-24 characters, lowercase letters and numbers only
param storageAccountName = 'stpumpsmanualskfdflmm'

// Name of the blob container
param containerName = 'pumps-manuals'
