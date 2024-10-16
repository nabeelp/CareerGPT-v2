/*
Copyright (c) Microsoft. All rights reserved.
Licensed under the MIT license. See LICENSE file in the project root for full license information.

Bicep template for deploying CopilotChat Azure resources.
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

@description('Existing Azure AI Search key')
param aiSearchKey string

@description('Whether to deploy Azure Speech Services to enable input by voice')
param deploySpeechServices bool = true

@description('Whether to deploy the web searcher plugin, which requires a Bing resource')
param deployWebSearcherPlugin bool = false

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

// Create Azure OpenAI resources
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
    minTlsVersion: '1.2'
    netFrameworkVersion: 'v6.0'
    use32BitWorkerProcess: false
    vnetRouteAllEnabled: true
    webSocketsEnabled: true
    appSettings: concat([
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
          value: 'ApiKey'
        }
        {
          name: 'KernelMemory:Services:AzureAISearch:Endpoint'
          value: deployNewAISearch ? 'https://${azureAISearch.name}.search.windows.net' : aiSearchEndpoint
        }
        {
          name: 'KernelMemory:Services:AzureAISearch:APIKey'
          value: deployNewAISearch ? azureAISearch.listAdminKeys().primaryKey : aiSearchKey
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
        {
          name: 'Plugins:0:Name'
          value: 'Klarna Shopping'
        }
        {
          name: 'Plugins:0:ManifestDomain'
          value: 'https://www.klarna.com'
        }
      ],
      (deployWebSearcherPlugin) ? [
        {
          name: 'Plugins:1:Name'
          value: 'WebSearcher'
        }
        {
          name: 'Plugins:1:ManifestDomain'
          value: 'https://${functionAppWebSearcherPlugin.properties.defaultHostName}'
        }
        {
          name: 'Plugins:1:Key'
          value: listkeys('${functionAppWebSearcherPlugin.id}/host/default/', '2022-09-01').functionKeys.default
        }
      ] : []
    )
  }
}

// Create memory pipeline resources
resource appServiceMemoryPipeline 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${uniqueName}-memorypipeline'
  location: location
  kind: 'app'
  tags: {
    skweb: '1'
  }
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource appServiceMemoryPipelineConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: appServiceMemoryPipeline
  name: 'web'
  properties: {
    alwaysOn: true
    detailedErrorLoggingEnabled: true
    minTlsVersion: '1.2'
    netFrameworkVersion: 'v6.0'
    use32BitWorkerProcess: false
    vnetRouteAllEnabled: true
    appSettings: [
      {
        name: 'KernelMemory:DocumentStorageType'
        value: 'AzureBlobs'
      }
      {
        name: 'KernelMemory:TextGeneratorType'
        value: aiService
      }
      {
        name: 'KernelMemory:DataIngestion:ImageOcrType'
        value: 'AzureFormRecognizer'
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
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureAISearch:Endpoint'
        value: deployNewAISearch ? 'https://${azureAISearch.name}.search.windows.net' : aiSearchEndpoint
      }
      {
        name: 'KernelMemory:Services:AzureAISearch:APIKey'
        value: deployNewAISearch ? azureAISearch.listAdminKeys().primaryKey : aiSearchKey
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
        name: 'KernelMemory:Services:AzureFormRecognizer:Auth'
        value: 'ApiKey'
      }
      {
        name: 'KernelMemory:Services:AzureFormRecognizer:Endpoint'
        value: ocrAccount.properties.endpoint
      }
      {
        name: 'KernelMemory:Services:AzureFormRecognizer:APIKey'
        value: ocrAccount.listKeys().key1
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
      {
        name: 'Logging:LogLevel:Default'
        value: 'Information'
      }
      {
        name: 'Logging:LogLevel:AspNetCore'
        value: 'Warning'
      }
      {
        name: 'Logging:ApplicationInsights:LogLevel:Default'
        value: 'Warning'
      }
      {
        name: 'ApplicationInsights:ConnectionString'
        value: appInsights.properties.ConnectionString
      }
    ]
  }
}

// Create Web Searcher Plugin resources
resource functionAppWebSearcherPlugin 'Microsoft.Web/sites@2022-09-01' = if (deployWebSearcherPlugin) {
  name: 'function-${uniqueName}-websearcher-plugin'
  location: location
  kind: 'functionapp'
  tags: {
    skweb: '1'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource functionAppWebSearcherPluginConfig 'Microsoft.Web/sites/config@2022-09-01' = if (deployWebSearcherPlugin) {
  parent: functionAppWebSearcherPlugin
  name: 'web'
  properties: {
    minTlsVersion: '1.2'
    appSettings: [
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'dotnet-isolated'
      }
      {
        name: 'AzureWebJobsStorage__accountName'
        value: storage.name
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsights.properties.InstrumentationKey
      }
      {
        name: 'PluginConfig:BingApiKey'
        value: (deployWebSearcherPlugin) ? bingSearchService.listKeys().key1 : ''
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

resource appInsightExtensionMemory 'Microsoft.Web/sites/siteextensions@2022-09-01' = {
  parent: appServiceMemoryPipeline
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}

resource appInsightExtensionWebSearchPlugin 'Microsoft.Web/sites/siteextensions@2022-09-01' = if (deployWebSearcherPlugin) {
  parent: functionAppWebSearcherPlugin
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

resource storageBlobAccessFunctionApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployWebSearcherPlugin) {
  name: guid('${functionAppWebSearcherPlugin.name}-storage-blob-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageBlobRoleDefinition.id
    principalId: functionAppWebSearcherPlugin.identity.principalId
  }
}

resource storageQueueAccessFunctionApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployWebSearcherPlugin) {
  name: guid('${functionAppWebSearcherPlugin.name}-storage-queue-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageQueueRoleDefinition.id
    principalId: functionAppWebSearcherPlugin.identity.principalId
  }
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

resource storageBlobAccessMemoryPipeline 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${appServiceMemoryPipeline.name}-storage-blob-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageBlobRoleDefinition.id
    principalId: appServiceMemoryPipeline.identity.principalId
  }
}

resource storageQueueAccessMemoryPipeline 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${appServiceMemoryPipeline.name}-storage-queue-access-${uniqueName}')
  scope: storage
  properties: {
    roleDefinitionId: storageQueueRoleDefinition.id
    principalId: appServiceMemoryPipeline.identity.principalId
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
    replicaCount: 1
    partitionCount: 1
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
resource customCosmosRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-04-15' = {
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

resource customCosmosRoleAccess 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
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
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
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
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource bingSearchService 'Microsoft.Bing/accounts@2020-06-10' = if (deployWebSearcherPlugin) {
  name: 'bing-search-${uniqueName}'
  location: 'global'
  sku: {
    name: 'S1'
  }
  kind: 'Bing.Search.v7'
}

// Generate outputs
output webapiUrl string = appServiceWeb.properties.defaultHostName
output webapiName string = appServiceWeb.name
output memoryPipelineName string = appServiceMemoryPipeline.name
output pluginNames array = concat(
  [],
  (deployWebSearcherPlugin) ? [ functionAppWebSearcherPlugin.name ] : []
)
