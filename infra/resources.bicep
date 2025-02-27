@description('Name of the Cognitive Search service to deploy')
param searchService_name string = ''
 
@description('Name of Cognitive Services (AIServices) resource')
param cognitiveService_name string = ''
 
@description('Name of the main “hub” AML workspace')
param workspaces_testaifoundry_name string = ''
 
@description('Name of the “project” AML workspace')
param workspace_testproject_name string = ''

@description('Tags to apply to all resources')
param tags object = {}

param location string = ''
 
var unique_searchService_name = empty(searchService_name) ? '${searchService_name}-${uniqueString(resourceGroup().id)}' : searchService_name
var unique_cognitiveService_name = empty(cognitiveService_name) ?'${cognitiveService_name}-${uniqueString(resourceGroup().id)}' : cognitiveService_name
var unique_workspaces_testaifoundry_name = empty(workspaces_testaifoundry_name) ? '${workspaces_testaifoundry_name}-${uniqueString(resourceGroup().id)}' : workspaces_testaifoundry_name
var unique_workspace_testproject_name = empty(workspace_testproject_name) ? '${workspace_testproject_name}-${uniqueString(resourceGroup().id)}' : workspace_testproject_name
var uniquie_storage_name = 'st${uniqueString(resourceGroup().id)}'
 
targetScope = 'resourceGroup'
 
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: uniquie_storage_name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}
 
 
 
/* -------------------------------------------------------------------
   COGNITIVE SERVICES (AIServices) ACCOUNT
   ------------------------------------------------------------------- */
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: unique_cognitiveService_name
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: unique_cognitiveService_name
    publicNetworkAccess: 'Enabled'
  }
}
 
/* Deploy text-embedding-3-large */
resource textEmbedding3Large 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: 'text-embedding-3-large'
  parent: cognitiveServices
  sku: {
    name: 'Standard'
    capacity: 17
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: 17
    raiPolicyName: 'Microsoft.DefaultV2'
  }
}
 
/* -------------------------------------------------------------------
   SEARCH SERVICE
   ------------------------------------------------------------------- */
resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: unique_searchService_name
  location: resourceGroup().location
  tags: {
    ProjectType: 'aoai-your-data-service'
  }
  sku: {
    name: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'Enabled'
    networkRuleSet: {
      ipRules: []
      bypass: 'None'
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: null
      }
    }
    disabledDataExfiltrationOptions: []
    semanticSearch: 'free'
   
  }
}
 
/* -------------------------------------------------------------------
   AML WORKSPACES (HUB + PROJECTS) & CONNECTIONS
   ------------------------------------------------------------------- */
 
/* The “Hub” AML workspace */
resource mlWorkspaceHub 'Microsoft.MachineLearningServices/workspaces@2024-07-01-preview' = {
  name: unique_workspaces_testaifoundry_name
  location: location
  sku: {
    name: 'Basic'
  }
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
 
  properties: {
    friendlyName: 'Testaifoundry'
    hbiWorkspace: false
    managedNetwork: {
      isolationMode: 'Disabled'
    }
    allowRoleAssignmentOnRG: true
    v1LegacyMode: false
    publicNetworkAccess: 'Enabled'
    ipAllowlist: []
    discoveryUrl: 'https://eastus.api.azureml.ms/discovery'
    enableSoftwareBillOfMaterials: false
    storageAccount: storageAccount.id
    associatedWorkspaces: [
      resourceId('Microsoft.MachineLearningServices/workspaces', unique_workspace_testproject_name)
    ]
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id
      enableDataIsolation: true
      systemDatastoresAuthMode: 'identity'
      enableServiceSideCMKEncryption: false
    }
  }
}
 
/* The “project” AML workspace */
resource mlWorkspaceProject 'Microsoft.MachineLearningServices/workspaces@2024-07-01-preview' = {
  name: unique_workspace_testproject_name
  location: location
  sku: {
    name: 'Basic'
  }
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
 
  properties: {
    friendlyName: unique_workspace_testproject_name
    hbiWorkspace: false
    enableSoftwareBillOfMaterials: false
    hubResourceId: mlWorkspaceHub.id
    enableDataIsolation: true
    systemDatastoresAuthMode: 'identity'
    enableServiceSideCMKEncryption: false
  }
}
 
/* -------------------------------------------------------------------
   Managed Identitiy ROLE ASSIGNMENT
   Hub
   Project
   Search Index Data Contributor - 8ebe5a00-799e-43f5-93ac-243d3dce84a7
   ------------------------------------------------------------------- */
var searchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
 
  resource roleAssignmentHub 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(resourceGroup().id, 'roleAssignmentHub')
    scope: searchService
    properties: {
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributor)// Search Index Data Contributor
      principalId: mlWorkspaceHub.identity.principalId// Replace with the actual principal ID
      principalType: 'ServicePrincipal'
     
    }
  }
 
resource roleAssignmentProject 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'roleAssignmentProject')
  scope: searchService
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributor) // Search Index Data Contributor
    principalId:  mlWorkspaceProject.identity.principalId// Replace with the actual principal ID
    principalType: 'ServicePrincipal'
  }
}
 
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

 
resource roleAssignmentProjectSearchService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'roleAssignmentProjectSearchService')
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor) // Search Index Data Contributor
    principalId:  searchService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
