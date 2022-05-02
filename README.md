# Azure Key Vault
This module will create an Azure Key Vault with Azure RBAC.

You can optionally configure network and firewall rules, diagnostics and resource lock.

## Usage

### Example 1 - Key Vault with diagnostics and resource lock

```bicep
param deploymentName string = 'keyvault${utcNow()}'
param location string = resourceGroup().location

module keyvault 'keyvault.bicep' = {
  name: deploymentName
  params: {
    keyVaultName: 'myKeyVault'
    location: location
    resourcelock: 'CanNotDelete'
    enableDiagnostics: true    
    diagnosticLogAnalyticsWorkspaceId: 'myLogAnalyticsWorkspaceResourceId'
  }
}
```

### Example 2 - Key Vault with network rules

```bicep
param deploymentName string = 'keyvault${utcNow()}'
param location string = resourceGroup().location

module keyvault 'keyvault.bicep' = {
  name: deploymentName
  params: {
    keyVaultName: 'myKeyVault'
    location: location
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
      ipRules: [
        {
          value: '172.32.0.0/24'
        }
      ]
      virtualNetworkRules: [
        {
          id: 'mySubnetResourceId'
          ignoreMissingVnetServiceEndpoint: true
        }
      ]
    }
    enableDiagnostics: true
    diagnosticLogGroup: 'audit'
    diagnosticLogAnalyticsWorkspaceId: 'myLogAnalyticsWorkspaceResourceId'
  }
}
```