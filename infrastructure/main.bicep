@description('Azure region for PowerOps resources')
param location string = resourceGroup().location

@description('Environment name')
@allowed([
  'dev'
  'staging'
  'production'
])
param environmentName string = 'dev'

@description('Container registry name')
param containerRegistryName string

// ---------------------------------------------------------
// Shared Configuration
// ---------------------------------------------------------

var commonTags = {
  project: 'PowerOps'
  environment: environmentName
  purpose: 'DevOps Portfolio'
}

var logAnalyticsName = 'log-powerops-${environmentName}'
var containerEnvironmentName = 'cae-powerops-${environmentName}'
var containerAppName = 'ca-powerops-${environmentName}'
var identityName = 'id-powerops-${environmentName}'

// PowerOps Docker image stored in Azure Container Registry
var powerOpsImage = '${containerRegistry.properties.loginServer}/powerops-api:1.0'

// Built-in AcrPull role
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// ---------------------------------------------------------
// Azure Container Registry
// ---------------------------------------------------------

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: containerRegistryName
  location: location

  sku: {
    name: 'Basic'
  }

  properties: {
    adminUserEnabled: false
  }

  tags: commonTags
}

// ---------------------------------------------------------
// User-Assigned Managed Identity
// ---------------------------------------------------------

resource powerOpsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: commonTags
}

// ---------------------------------------------------------
// AcrPull RBAC Role Assignment
// ---------------------------------------------------------

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    containerRegistry.id,
    powerOpsIdentity.id,
    acrPullRoleDefinitionId
  )

  scope: containerRegistry

  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: powerOpsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------
// Log Analytics Workspace
// ---------------------------------------------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsName
  location: location

  properties: {
    retentionInDays: 30

    sku: {
      name: 'PerGB2018'
    }
  }

  tags: commonTags
}

// ---------------------------------------------------------
// Azure Container Apps Environment
// ---------------------------------------------------------

resource containerEnvironment 'Microsoft.App/managedEnvironments@2025-07-01' = {
  name: containerEnvironmentName
  location: location

  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'

      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }

  tags: commonTags
}

// ---------------------------------------------------------
// PowerOps Azure Container App
// ---------------------------------------------------------

resource powerOpsContainerApp 'Microsoft.App/containerApps@2026-01-01' = {
  name: containerAppName
  location: location

  identity: {
    type: 'UserAssigned'

    userAssignedIdentities: {
      '${powerOpsIdentity.id}': {}
    }
  }

  properties: {
    environmentId: containerEnvironment.id

    configuration: {
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: powerOpsIdentity.id
        }
      ]

      activeRevisionsMode: 'Single'

      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'

        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }

    template: {
      containers: [
        {
          name: 'powerops-api'
          image: powerOpsImage

          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }

          probes: [
            {
              type: 'Liveness'

              httpGet: {
                path: '/health'
                port: 8080
                scheme: 'HTTP'
              }

              initialDelaySeconds: 10
              periodSeconds: 30
              timeoutSeconds: 5
              failureThreshold: 3
            }
          ]
        }
      ]

      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }

  tags: commonTags

  dependsOn: [
    acrPullRoleAssignment
  ]
}

// ---------------------------------------------------------
// Outputs
// ---------------------------------------------------------

output registryName string = containerRegistry.name
output registryLoginServer string = containerRegistry.properties.loginServer
output managedIdentityName string = powerOpsIdentity.name
output logAnalyticsWorkspace string = logAnalytics.name
output containerAppsEnvironment string = containerEnvironment.name
output containerAppName string = powerOpsContainerApp.name
output containerAppFqdn string = powerOpsContainerApp.properties.configuration.ingress.fqdn
