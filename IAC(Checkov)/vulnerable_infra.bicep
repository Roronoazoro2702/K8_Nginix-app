// Vulnerable Bicep Template for Azure Resources - FOR TESTING PURPOSES ONLY
// This file contains intentional security misconfigurations for IaC scanner testing

// Parameters
param location string = 'eastus'
param environmentName string = 'dev'
param adminUsername string = 'adminuser'
param adminPassword string = 'Password123!' // Hardcoded password - vulnerability

// Variables
var storageName = 'storage${uniqueString(resourceGroup().id)}'
var appServicePlanName = 'appplan-${environmentName}'
var appServiceName = 'webapp-${environmentName}'
var sqlServerName = 'sqlserver-${environmentName}'
var sqlDatabaseName = 'sqldb-${environmentName}'
var vnetName = 'vnet-${environmentName}'
var keyVaultName = 'kv-${environmentName}'
var functionAppName = 'func-${environmentName}'
var containerRegistryName = 'acr${uniqueString(resourceGroup().id)}'

// Storage Account - Multiple vulnerabilities
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: false // Vulnerability: HTTP allowed
    allowBlobPublicAccess: true     // Vulnerability: Public access allowed
    minimumTlsVersion: 'TLS1_0'     // Vulnerability: Outdated TLS version
    networkAcls: {
      defaultAction: 'Allow'        // Vulnerability: Allow all by default
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: false           // Vulnerability: Blob encryption disabled
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

// Web App - Multiple vulnerabilities
resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false              // Vulnerability: HTTP allowed
    clientCertEnabled: false      // Vulnerability: No client certificates
    siteConfig: {
      ftpsState: 'AllAllowed'     // Vulnerability: FTP enabled
      http20Enabled: false        // Vulnerability: HTTP 2.0 disabled
      minTlsVersion: '1.0'        // Vulnerability: Outdated TLS version
      remoteDebuggingEnabled: true // Vulnerability: Remote debugging enabled
      webSocketsEnabled: true     // Vulnerability: WebSockets enabled without proper security
      cors: {
        allowedOrigins: [
          '*'                     // Vulnerability: CORS allows all origins
        ]
      }
      appSettings: [
        {
          name: 'SECRET_KEY'
          value: 'actualsecretvalue123' // Vulnerability: Hardcoded secret
        }
      ]
    }
  }
  identity: {
    type: 'None'                  // Vulnerability: No managed identity
  }
}

// SQL Server - Multiple vulnerabilities
resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword // Vulnerability: Using parameter with hardcoded password
    version: '12.0'
    publicNetworkAccess: 'Enabled'  // Vulnerability: Public access enabled
    minimalTlsVersion: '1.0'        // Vulnerability: Outdated TLS version
  }
}

// SQL Firewall Rule - allows all Azure IPs
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2021-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'     // Vulnerability: Too permissive
    endIpAddress: '255.255.255.255'
  }
}

// SQL Database - Vulnerability
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 104857600
    zoneRedundant: false         // Vulnerability: No zone redundancy
    readScale: 'Disabled'        // Vulnerability: No read scaling
    requestedBackupStorageRedundancy: 'Local' // Vulnerability: Only local backup
  }
}

// Virtual Network with weak NSG rules
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Network Security Group with overly permissive rules
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${environmentName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-all-inbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'            // Vulnerability: All protocols
          sourceAddressPrefix: '*' // Vulnerability: All sources
          sourcePortRange: '*'     // Vulnerability: All source ports
          destinationAddressPrefix: '*' // Vulnerability: All destinations
          destinationPortRange: '*'     // Vulnerability: All destination ports
        }
      }
    ]
  }
}

// Key Vault with vulnerabilities
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: false       // Vulnerability: Soft delete disabled
    enablePurgeProtection: false  // Vulnerability: No purge protection
    enableRbacAuthorization: false // Vulnerability: RBAC not enabled
    tenantId: subscription().tenantId
    networkAcls: {
      defaultAction: 'Allow'      // Vulnerability: Allow all by default
      bypass: 'AzureServices'
    }
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: '00000000-0000-0000-0000-000000000000' // Placeholder objectId
        permissions: {
          keys: [
            'all'                 // Vulnerability: Too permissive
          ]
          secrets: [
            'all'                 // Vulnerability: Too permissive
          ]
          certificates: [
            'all'                 // Vulnerability: Too permissive
          ]
        }
      }
    ]
  }
}

// Function App with vulnerabilities
resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: false              // Vulnerability: HTTP allowed
    clientCertEnabled: false
    siteConfig: {
      http20Enabled: false
      minTlsVersion: '1.0'        // Vulnerability: Outdated TLS
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}' // Vulnerability: Exposed storage key
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'             // Vulnerability: Outdated version
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'API_KEY'
          value: 'secretapikey123' // Vulnerability: Hardcoded key
        }
      ]
    }
  }
  identity: {
    type: 'None'                  // Vulnerability: No managed identity
  }
}

// Container Registry with vulnerabilities
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'                 // Vulnerability: Basic SKU doesn't support private links
  }
  properties: {
    adminUserEnabled: true        // Vulnerability: Admin user enabled
    policies: {
      quarantinePolicy: {
        status: 'disabled'        // Vulnerability: No quarantine policy
      }
      trustPolicy: {
        status: 'disabled'        // Vulnerability: No trust policy
      }
      retentionPolicy: {
        status: 'disabled'        // Vulnerability: No retention policy
      }
    }
    encryption: {
      status: 'disabled'          // Vulnerability: Encryption disabled
    }
    publicNetworkAccess: 'Enabled' // Vulnerability: Public access enabled
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output webAppName string = webApp.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output keyVaultUri string = keyVault.properties.vaultUri