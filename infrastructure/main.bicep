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

// Key Vault names must be globally unique
var keyVaultName = 'kv-${environmentName}-${substring(uniqueString(resourceGroup().id, environmentName), 0, 8)}'

// Fictional secret name used for portfolio demonstration
var weatherApiSecretName = 'WeatherApiKey'

// PowerOps Docker image stored in Azure Container Registry
var powerOpsImage = '${containerRegistry.properties.loginServer}/powerops-api:1.0'

// Azure Monitor alert name
var unhealthyAlertName = 'alert-powerops-unhealthy-${environmentName}'

// ---------------------------------------------------------
// Azure Built-In RBAC Roles
// ---------------------------------------------------------

// AcrPull role
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// Key Vault Secrets User role
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
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
// ACR Pull RBAC
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
// Azure Key Vault
// ---------------------------------------------------------

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: keyVaultName
  location: location

  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true

    sku: {
      family: 'A'
      name: 'standard'
    }
  }

  tags: commonTags
}

// ---------------------------------------------------------
// Key Vault Secrets User RBAC
// ---------------------------------------------------------

resource keyVaultSecretsRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    keyVault.id,
    powerOpsIdentity.id,
    keyVaultSecretsUserRoleDefinitionId
  )

  scope: keyVault

  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
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
// Azure Monitor Log Alert
// Detects HTTP 500 or 503 responses
// ---------------------------------------------------------

resource unhealthyServiceAlert 'Microsoft.Insights/scheduledQueryRules@2025-01-01-preview' = {
  name: unhealthyAlertName
  location: location
  kind: 'LogAlert'

  properties: {
    displayName: 'PowerOps unhealthy HTTP responses - ${environmentName}'
    description: 'Alerts when PowerOps logs HTTP 500 or HTTP 503 responses.'
    severity: 2
    enabled: true

    scopes: [
      logAnalytics.id
    ]

    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'

    criteria: {
      allOf: [
        {
          query: '''
ContainerAppConsoleLogs_CL
| where ContainerAppName_s startswith "ca-powerops-"
| where Log_s contains "responded 500" or Log_s contains "responded 503"
'''

          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }

    autoMitigate: true
    skipQueryValidation: true
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

  // Attach managed identity
  identity: {
    type: 'UserAssigned'

    userAssignedIdentities: {
      '${powerOpsIdentity.id}': {}
    }
  }

  properties: {
    environmentId: containerEnvironment.id

    configuration: {

      // ---------------------------------------------------
      // Secure Key Vault Secret Reference
      // ---------------------------------------------------

      secrets: [
        {
          name: 'weather-api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${weatherApiSecretName}'
          identity: powerOpsIdentity.id
        }
      ]

      // ---------------------------------------------------
      // Azure Container Registry Authentication
      // ---------------------------------------------------

      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: powerOpsIdentity.id
        }
      ]

      // ---------------------------------------------------
      // Revision Strategy
      // ---------------------------------------------------

      activeRevisionsMode: 'Single'

      // ---------------------------------------------------
      // Public Ingress
      // ---------------------------------------------------

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

    // -----------------------------------------------------
    // Container Configuration
    // -----------------------------------------------------

    template: {
      containers: [
        {
          name: 'powerops-api'
          image: powerOpsImage

          // Secret supplied securely from Key Vault
          env: [
            {
              name: 'WeatherApi__ApiKey'
              secretRef: 'weather-api-key'
            }
          ]

          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }

          // -------------------------------------------------
          // Application Health Check
          // -------------------------------------------------

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

      // ---------------------------------------------------
      // Autoscaling
      // ---------------------------------------------------

      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }

  tags: commonTags

  dependsOn: [
    acrPullRoleAssignment
    keyVaultSecretsRoleAssignment
  ]
}

// ---------------------------------------------------------
// Outputs
// ---------------------------------------------------------

output registryName string = containerRegistry.name

output registryLoginServer string = containerRegistry.properties.loginServer

output managedIdentityName string = powerOpsIdentity.name

output keyVaultName string = keyVault.name

output keyVaultUri string = keyVault.properties.vaultUri

output logAnalyticsWorkspace string = logAnalytics.name

output containerAppsEnvironment string = containerEnvironment.name

output containerAppName string = powerOpsContainerApp.name

output containerAppFqdn string = powerOpsContainerApp.properties.configuration.ingress.fqdn

output unhealthyAlertRuleName string = unhealthyServiceAlert.name
