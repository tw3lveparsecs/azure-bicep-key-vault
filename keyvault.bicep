@description('The name of the resource.')
param keyVaultName string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Object containing resource tags.')
param tags object = {}

@description('Key Vault SKU. Standard or Premium.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Allows Azure VMs to access KeyVault.')
param enabledForDeployment bool = true

@description('Allows Azure Disk Encryption service to access KeyVault.')
param enabledForDiskEncryption bool = true

@description('Allows Azure Resource Manager to access KeyVault during deployments.')
param enabledForTemplateDeployment bool = true

@description('Rule definitions governing the KeyVault network access.')
@metadata({
  bypass: 'Allow Azure Services to bypass Network ACLs. Accepted values: "AzureServices", "None".'
  defaultAction: 'The default action when no rules match. Accepted values: "Allow", "Deny".'
  ipRules: [
    {
      value: 'IPv4 address or CIDR range.'
    }
  ]
  virtualNetworkRules: [
    {
      id: 'Full resource id of a vnet subnet.'
      ignoreMissingVnetServiceEndpoint: 'Whether to ignore if vnet subnet is missing service endpoints. Accepted values: "true", "false".'
    }
  ]
})
param networkAcls object = {}

@description('Soft delete retention period.')
param softDeleteRetentionInDays int = 90

@description('Enable purge protection.')
param enablePurgeProtection bool = true

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Specify the type of resource lock.')
param resourcelock string = 'NotSpecified'

@description('Enable diagnostic logs')
param enableDiagnostics bool = false

@allowed([
  'allLogs'
  'audit'
])
@description('Specify the type of diagnostic logs to monitor.')
param diagnosticLogGroup string = 'allLogs'

@description('Storage account resource id. Only required if enableDiagnostics is set to true.')
param diagnosticStorageAccountId string = ''

@description('Log analytics workspace resource id. Only required if enableDiagnostics is set to true.')
param diagnosticLogAnalyticsWorkspaceId string = ''

@description('Event hub authorization rule for the Event Hubs namespace. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Event hub name. Only required if enableDiagnostics is set to true.')
param diagnosticEventHubName string = ''

var lockName = toLower('${keyvault.name}-${resourcelock}-lck')
var diagnosticsName = '${keyvault.name}-dgs'

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection ? true : null
    enableRbacAuthorization: true
    networkAcls: {
      bypass: contains(networkAcls, 'bypass') ? networkAcls.bypass : null
      defaultAction: contains(networkAcls, 'defaultAction') ? networkAcls.defaultAction : null
      ipRules: contains(networkAcls, 'ipRules') ? networkAcls.ipRules : null
      virtualNetworkRules: contains(networkAcls, 'virtualNetworkRules') ? networkAcls.virtualNetworkRules : null
    }
  }
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = if (resourcelock != 'NotSpecified') {
  name: lockName
  properties: {
    level: resourcelock
    notes: (resourcelock == 'CanNotDelete') ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: keyvault
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: keyvault
  name: diagnosticsName
  properties: {
    workspaceId: empty(diagnosticLogAnalyticsWorkspaceId) ? null : diagnosticLogAnalyticsWorkspaceId
    storageAccountId: empty(diagnosticStorageAccountId) ? null : diagnosticStorageAccountId
    eventHubAuthorizationRuleId: empty(diagnosticEventHubAuthorizationRuleId) ? null : diagnosticEventHubAuthorizationRuleId
    eventHubName: empty(diagnosticEventHubName) ? null : diagnosticEventHubName
    logs: [
      {
        categoryGroup: diagnosticLogGroup
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output name string = keyvault.name
output id string = keyvault.id
