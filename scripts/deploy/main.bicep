/*
TODO: Ensure that identity used to deploy has permissions to do role assignments
*/

@description('Name for the deployment consisting of alphanumeric characters or dashes (\'-\')')
param name string = 'copichat'

@description('SKU for the Azure App Service plan')
@allowed([ 'B1', 'S1', 'S2', 'S3', 'P1V3', 'P2V3', 'I1V2', 'I2V2' ])
param webAppServiceSku string = 'B1'

@description('Underlying AI service')
param aiService string = 'AzureOpenAI'

@description('Model to use for chat completions')
param completionModel string = 'gpt-4o'

@description('Model to use for text embeddings')
param embeddingModel string = 'text-embedding-ada-002'

@description('Azure OpenAI endpoint')
param aiEndpoint string = ''

//@secure()
@description('Azure OpenAI key')
param aiApiKey string

@description('Azure AD client ID for the backend web API')
param webApiClientId string

@description('Azure AD client ID for the frontend')
param frontendClientId string

@description('Azure AD tenant ID for authenticating users')
param azureAdTenantId string

@description('Azure AD cloud instance for authenticating users')
param azureAdInstance string = environment().authentication.loginEndpoint

@description('Whether to deploy a new Azure OpenAI instance')
param deployNewAzureOpenAI bool = false

@description('Whether to deploy Cosmos DB for persistent chat storage')
param deployCosmosDB bool = true

@description('What method to use to persist embeddings')
param memoryStore string = 'AzureAISearch'

@description('Whether to deploy a new Azure AI Search instance')
param deployNewAISearch bool = false

@description('Existing Azure AI Search endpoint')
param aiSearchEndpoint string

@description('Whether to deploy Azure Speech Services to enable input by voice')
param deploySpeechServices bool = true

@description('Region for the resources')
param location string = resourceGroup().location

@description('Custom name for the web app')
param customWebAppName string

@description('Hash of the resource group ID')
var rgIdHash = uniqueString(resourceGroup().id)

@description('Deployment name unique to resource group')
var uniqueName = '${name}-${rgIdHash}'

@description('Name of the Web App to create, use the value in customWebAppName, if provided')
var webAppName = customWebAppName == null ? 'app-${uniqueName}-webapi' : customWebAppName

// Virtual network resources
resource vNetNSG_default 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-default-${uniqueName}'
  location: location
  properties: {
    securityRules: []
  }
}

resource vNetNSG_appservice 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-appservice-${uniqueName}'
  location: location
  properties: {
    securityRules: []
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2024-03-01' = {
  name: 'vnet-${uniqueName}'
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
            id: vNetNSG_default.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'app-service'
        properties: {
          addressPrefix: '10.0.1.0/28'
          networkSecurityGroup: {
            id: vNetNSG_appservice.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                  serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Private DNS Zones
resource privateblob_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}

resource privatecog_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
}

resource privatecosmos_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
}

resource privateque_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'global'
}

resource privatesearch_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.search.windows.net'
  location: 'global'
}

resource privatetable_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'global'
}

resource privateweb_DNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

// Private DNS Zone links
resource privateblob_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateblob_DNSZone
  name: 'privateblob_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privatecog_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatecog_DNSZone
  name: 'privatecog_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privatecosmos_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatecosmos_DNSZone
  name: 'privatecosmos_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privateque_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateque_DNSZone
  name: 'privateque_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privatesearch_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatesearch_DNSZone
  name: 'privatesearch_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privatetable_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privatetable_DNSZone
  name: 'privatetable_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

resource privateweb_Link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateweb_DNSZone
  name: 'privateweb_Link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNet.id
    }
  }
}

// Private Endpoints
resource privateblob_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: 'privateblob_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privateblob-linkConnection'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privatecog_Ocr_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: 'privatecog_Ocr_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatecog-ocr-linkConnection'
        properties: {
          privateLinkServiceId: ocrAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource privatecog_Speech_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = if (deploySpeechServices) {
  name: 'privatecog_Speech_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatecog-speech-linkConnection'
        properties: {
          privateLinkServiceId: speechAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

resource privatecosmos_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = if (deployCosmosDB) {
  name: 'privatecosmos_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatecosmos-linkConnection'
        properties: {
          privateLinkServiceId: cosmosAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource privateque_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: 'privateque_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privateque-linkConnection'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource privatesearch_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = if (deployNewAISearch) {
  name: 'privatesearch_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatesearch-linkConnection'
        properties: {
          privateLinkServiceId: azureAISearch.id
          groupIds: [
            'searchService'
          ]
        }
      }
    ]
  }
}

resource privatetable_Endpoint 'Microsoft.Network/privateEndpoints@2024-03-01' = {
  name: 'privatetable_Endpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'default')
    }
    privateLinkServiceConnections: [
      {
        name: 'privatetable-linkConnection'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

// DNS Zone Groups
resource privateblob_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privateblob_Endpoint
  name: 'privateblob_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateblob_DNSZone.id
        }
      }
    ]
  }
}

resource privatecog_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privatecog_Ocr_Endpoint
  name: 'privatecog_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privatecog_DNSZone.id
        }
      }
    ]
  }
}

resource privatecog_Speech_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = if (deploySpeechServices) {
  parent: privatecog_Speech_Endpoint
  name: 'privatecog_Speech_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privatecog_DNSZone.id
        }
      }
    ]
  }
}

resource privatecosmos_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = if (deployCosmosDB) {
  parent: privatecosmos_Endpoint
  name: 'privatecosmos_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privatecosmos_DNSZone.id
        }
      }
    ]
  }
}

resource privateque_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privateque_Endpoint
  name: 'privateque_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateque_DNSZone.id
        }
      }
    ]
  }
}

resource privatetable_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  parent: privatetable_Endpoint
  name: 'privatetable_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privatetable_DNSZone.id
        }
      }
    ]
  }
}

resource privatesearch_DnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = if (deployNewAISearch) {
  parent: privatesearch_Endpoint
  name: 'privatesearch_DnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privatesearch_DNSZone.id
        }
      }
    ]
  }
}

// Create Azure OpenAI resources
resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = if (deployNewAzureOpenAI) {
  name: 'ai-${uniqueName}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: toLower(uniqueName)
  }
}

resource openAI_completionModel 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployNewAzureOpenAI) {
  parent: openAI
  name: completionModel
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: completionModel
    }
  }
}

resource openAI_embeddingModel 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployNewAzureOpenAI) {
  parent: openAI
  name: embeddingModel
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: embeddingModel
    }
  }
  dependsOn: [// This "dependency" is to create models sequentially because the resource
    openAI_completionModel // provider does not support parallel creation of models properly.
  ]
}

// Create app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${uniqueName}-webapi'
  location: location
  kind: 'app'
  sku: {
    name: webAppServiceSku
  }
}

// Create Web API + Frontend resources
resource appServiceWeb 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app'
  tags: {
    skweb: '1'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      healthCheckPath: '/healthz'
    }
    vnetRouteAllEnabled: true
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vNet.name, 'app-service')
    publicNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appServiceWebConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: appServiceWeb
  name: 'web'
  properties: {
    alwaysOn: false
    cors: {
      allowedOrigins: [
        'http://localhost:3000'
        'https://localhost:3000'
      ]
      supportCredentials: true
    }
    detailedErrorLoggingEnabled: true
    minTlsVersion: '1.3'
    netFrameworkVersion: 'v6.0'
    use32BitWorkerProcess: false
    vnetName: vNet.name
    vnetRouteAllEnabled: true
    webSocketsEnabled: true
    appSettings: [
      {
        name: 'Authentication:Type'
        value: 'AzureAd'
      }
      {
        name: 'Authentication:AzureAd:Instance'
        value: azureAdInstance
      }
      {
        name: 'Authentication:AzureAd:TenantId'
        value: azureAdTenantId
      }
      {
        name: 'Authentication:AzureAd:ClientId'
        value: webApiClientId
      }
      {
        name: 'Authentication:AzureAd:Scopes'
        value: 'access_as_user'
      }
      {
        name: 'ChatStore:Type'
        value: deployCosmosDB ? 'cosmos' : 'volatile'
      }
      {
        name: 'ChatStore:Cosmos:Database'
        value: 'CopilotChat'
      }
      {
        name: 'ChatStore:Cosmos:ChatSessionsContainer'
        value: 'chatsessions'
      }
      {
        name: 'ChatStore:Cosmos:ChatMessagesContainer'
        value: 'chatmessages'
      }
      {
        name: 'ChatStore:Cosmos:ChatMemorySourcesContainer'
        value: 'chatmemorysources'
      }
      {
        name: 'ChatStore:Cosmos:ChatParticipantsContainer'
        value: 'chatparticipants'
      }
      {
        name: 'ChatStore:Cosmos:ConnectionString'
        value: deployCosmosDB ? cosmosAccount.properties.documentEndpoint : ''
      }
      {
        name: 'AzureSpeech:Region'
        value: location
      }
      {
        name: 'AzureSpeech:Key'
        value: deploySpeechServices ? speechAccount.listKeys().key1 : ''
      }
      {
        name: 'AllowedOrigins'
        value: '[*]' // Defer list of allowed origins to the Azure service app's CORS configuration
      }
      {
        name: 'Kestrel:Endpoints:Https:Url'
        value: 'https://localhost:443'
      }
      {
        name: 'Frontend:AadClientId'
        value: frontendClientId
      }
      {
        name: 'Logging:LogLevel:Default'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:CopilotChat.WebApi'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.SemanticKernel'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.AspNetCore.Hosting'
        value: 'Warning'
      }
      {
        name: 'Logging:LogLevel:Microsoft.Hosting.Lifetimel'
        value: 'Warning'
      }
      {
        name: 'Logging:ApplicationInsights:LogLevel:Default'
        value: 'Warning'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: appInsights.properties.ConnectionString
      }
      {
        name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
        value: '~2'
      }
      {
        name: 'KernelMemory:DocumentStorageType'
        value: 'AzureBlobs'
      }
      {
        name: 'KernelMemory:TextGeneratorType'
        value: aiService
      }
      {
        name: 'KernelMemory:DataIngestion:OrchestrationType'
        value: 'Distributed'
      }
      {
        name: 'KernelMemory:DataIngestion:DistributedOrchestration:QueueType'
        value: 'AzureQueue'
      }
      {
        name: 'KernelMemory:DataIngestion:EmbeddingGeneratorTypes:0'
        value: aiService
      }
      {
        name: 'KernelMemory:DataIngestion:MemoryDbTypes:0'
        value: memoryStore
      }
      {
        name: 'KernelMemory:Retrieval:MemoryDbType'
        value: memoryStore
      }
      {
        name: 'KernelMemory:Retrieval:EmbeddingGeneratorType'
        value: aiService
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:Auth'
        value: 'AzureIdentity'
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:Account'
        value: storage.name
      }
      {
        name: 'KernelMemory:Services:AzureBlobs:Container'
        value: 'chatmemory'
      }
      {
        name: 'KernelMemory:Services:AzureQueue:Auth'
        value: 'AzureIdentity'
      }
      {
        name: 'KernelMemory:Services:AzureQueue:Account'
        value: storage.name
      }
      {
        name: 'KernelMemory:Services:AzureAISearch:Auth'
        value: 'AzureIdentity'
      }
      {
        name: 'KernelMemory:Services:AzureAISearch:Endpoint'
        value: deployNewAISearch ? 'https://${azureAISearch.name}.search.windows.net' : aiSearchEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Endpoint'
        value: deployNewAzureOpenAI ? openAI.properties.endpoint : aiEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:APIKey'
        value: deployNewAzureOpenAI ? openAI.listKeys().key1 : aiApiKey
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIText:Deployment'
        value: completionModel
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Endpoint'
        value: deployNewAzureOpenAI ? openAI.properties.endpoint : aiEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:APIKey'
        value: deployNewAzureOpenAI ? openAI.listKeys().key1 : aiApiKey
      }
      {
        name: 'KernelMemory:Services:AzureOpenAIEmbedding:Deployment'
        value: embeddingModel
      }
      {
        name: 'KernelMemory:Services:OpenAI:TextModel'
        value: completionModel
      }
      {
        name: 'KernelMemory:Services:OpenAI:EmbeddingModel'
        value: embeddingModel
      }
      {
        name: 'KernelMemory:Services:OpenAI:APIKey'
        value: aiApiKey
      }
    ]
  }
}

// Create and configure App Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appins-${uniqueName}'
  location: location
  kind: 'string'
  tags: {
    displayName: 'AppInsight'
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appInsightExtensionWeb 'Microsoft.Web/sites/siteextensions@2022-09-01' = {
  parent: appServiceWeb
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'la-${uniqueName}'
  location: location
  tags: {
    displayName: 'Log Analytics'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Create storage account for function app
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'st${rgIdHash}' // Not using full unique name to avoid hitting 24 char limit
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled'
  }
}

// Assign access to the funciton app, web api and the memory pipeline apps to the storage account (blob and queues)
@description('This is the built-in Storage Blob Data Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage')
resource storageBlobRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

@description('This is the built-in Storage Queue Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage')
resource storageQueueRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}

resource storageBlobAccessWebApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${appServiceWeb.name}-storage-blob-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageBlobRoleDefinition.id
    principalId: appServiceWeb.identity.principalId
  }
}

resource storageQueueAccessWebApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${appServiceWeb.name}-storage-queue-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageQueueRoleDefinition.id
    principalId: appServiceWeb.identity.principalId
  }
}

// Create Azure AI Search resources
resource azureAISearch 'Microsoft.Search/searchServices@2022-09-01' = if (deployNewAISearch) {
  name: 'acs-${uniqueName}'
  location: location
  sku: {
    name: 'basic'
  }
  properties: {
    disableLocalAuth: true
    replicaCount: 1
    partitionCount: 1
    publicNetworkAccess: 'disabled'
  }
}

// Assign access to the search resource for the web identity 
@description('This is the built-in Search Index Data Reader role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage:~:text=Search%20Index%20Data%20Reader')
resource searchReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = if (deployNewAISearch){
  scope: subscription()
  name: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
}

resource searchReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployNewAISearch){
  name: guid('${appServiceWeb.name}-search-reader-${uniqueName}')
  scope: azureAISearch
  properties: {
    roleDefinitionId: searchReaderRoleDefinition.id
    principalId: appServiceWeb.identity.principalId
  }
}

// Create CosmosDB resources
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = if (deployCosmosDB) {
  name: toLower('cosmos-${uniqueName}')
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [ {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosAccount
  name: 'CopilotChat'
  properties: {
    resource: {
      id: 'CopilotChat'
    }
  }
}

resource messageContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatmessages'
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 1000
      }
    }
    resource: {
      id: 'chatmessages'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/chatId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource sessionContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatsessions'
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 1000
      }
    }
    resource: {
      id: 'chatsessions'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource participantContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatparticipants'
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 1000
      }
    }
    resource: {
      id: 'chatparticipants'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/userId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

resource memorySourcesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = if (deployCosmosDB) {
  parent: cosmosDatabase
  name: 'chatmemorysources'
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 1000
      }
    }
    resource: {
      id: 'chatmemorysources'
      indexingPolicy: {
        indexingMode: 'consistent'
        automatic: true
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: [
          '/chatId'
        ]
        kind: 'Hash'
        version: 2
      }
    }
  }
}

// Create custom Cosmos role and assign to web app identity
resource customCosmosRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-04-15' = if (deployCosmosDB) {
  name: guid('custom-cosmos-role-${uniqueName}')
  parent: cosmosAccount
  properties: {
    roleName: 'CustomPasswordlessReadWrite'
    type: 'CustomRole'
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
        ]
      }
    ]
    assignableScopes: [
      cosmosAccount.id
    ]
  }
}

resource customCosmosRoleAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = if (deployCosmosDB) {
  name: guid('web-api-cosmos-access-${uniqueName}')
  parent: cosmosAccount
  properties: {
    roleDefinitionId: customCosmosRole.id
    principalId: appServiceWeb.identity.principalId
    scope: cosmosAccount.id
  }
}

// Create Cognitive Services resources
resource speechAccount 'Microsoft.CognitiveServices/accounts@2022-12-01' = if (deploySpeechServices) {
  name: 'cog-speech-${uniqueName}'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'SpeechServices'
  identity: {
    type: 'None'
  }
  properties: {
    customSubDomainName: 'cog-speech-${uniqueName}'
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource ocrAccount 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: 'cog-ocr-${uniqueName}'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  identity: {
    type: 'None'
  }
  properties: {
    customSubDomainName: 'cog-ocr-${uniqueName}'
    disableLocalAuth:true
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Disabled'
  }
}

// Generate outputs
output webapiUrl string = appServiceWeb.properties.defaultHostName
output webapiName string = appServiceWeb.name
