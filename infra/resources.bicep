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

param currentUserId string

param location string = ''
 
var unique_searchService_name = empty(searchService_name) ? '${searchService_name}-${uniqueString(resourceGroup().id)}' : searchService_name
var unique_cognitiveService_name = empty(cognitiveService_name) ?'${cognitiveService_name}-${uniqueString(resourceGroup().id)}' : cognitiveService_name
var unique_workspaces_testaifoundry_name = empty(workspaces_testaifoundry_name) ? '${workspaces_testaifoundry_name}-${uniqueString(resourceGroup().id)}' : workspaces_testaifoundry_name
var unique_workspace_testproject_name = empty(workspace_testproject_name) ? '${workspace_testproject_name}-${uniqueString(resourceGroup().id)}' : workspace_testproject_name
var uniquie_storage_name = 'st${uniqueString(resourceGroup().id)}'
 
targetScope = 'resourceGroup'
 
/* -------------------------------------------------------------------
   STORAGE ACCOUNT
   ------------------------------------------------------------------- */

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.0' = {
  name: 'storageAccountDeployment'
  params: {

    name: uniquie_storage_name
    
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true  
    location: location
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}
 
 
/* -------------------------------------------------------------------
   COGNITIVE SERVICES (AIServices) ACCOUNT
   ------------------------------------------------------------------- */
module cognitiveServices 'br/public:avm/res/cognitive-services/account:0.10.0' = {
  name: 'accountDeployment'
  params:{
    name: unique_cognitiveService_name
    location: location
    tags: tags
    sku: 'S0'
    kind: 'AIServices'
    disableLocalAuth: false
    managedIdentities: {
      systemAssigned: true
    }
  
    customSubDomainName: unique_cognitiveService_name
    publicNetworkAccess: 'Enabled'
    deployments:[
      {
        model: {
          name: 'text-embedding-3-large'
          format: 'OpenAI'
          version: '1'
        }
        name: 'text-embedding-3-large'
        sku: {
          name: 'Standard'
          capacity: 17
        }
        raiPolicyName: 'Microsoft.DefaultV2'
      }

    ]  
  }
  
}
 

 
/* -------------------------------------------------------------------
   SEARCH SERVICE
   ------------------------------------------------------------------- */
module searchService 'br/public:avm/res/search/search-service:0.9.0' = {
    name: 'searchServiceDeployment'
    params: {
      // Required parameters
      name: unique_searchService_name
      // Non-required parameters
      location: location
      tags:tags
      sku: 'standard'
      managedIdentities: {
        systemAssigned: true
      }
      replicaCount: 1
      partitionCount: 1
      hostingMode: 'default'
      publicNetworkAccess: 'Enabled'
      networkRuleSet: {
        ipRules: []
        bypass: 'None'
      }
      disableLocalAuth: false
      authOptions: {
        aadOrApiKey: {
          aadAuthFailureMode: null
        }
      }
      semanticSearch: 'free'
    }
  }

 
/* -------------------------------------------------------------------
   AML WORKSPACES (HUB + PROJECTS) & CONNECTIONS
   ------------------------------------------------------------------- */
 
/* The “Hub” AML workspace */
module mlWorkspaceHub 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'workspaceDeployment'
  params: {
    // Required parameters
    name: unique_workspaces_testaifoundry_name
    kind: 'Hub'
    
    managedIdentities: {
      systemAssigned: true
    }
    sku: 'Basic'
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    location: location
    publicNetworkAccess: 'Enabled'
  }
}

 
/* The “project” AML workspace */
module workspaceProject 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'workspaceProjectDeployment'
  params: {
    // Required parameters
    name: unique_workspace_testproject_name
    kind: 'Project'
    sku: 'Basic'
    // Non-required parameters
    hubResourceId: mlWorkspaceHub.outputs.resourceId
    systemDatastoresAuthMode: 'identity'
    location: location
    hbiWorkspace: false
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccess: 'Enabled'
  }
}




/* -------------------------------------------------------------------
   Managed Identitiy ROLE ASSIGNMENT
   Hub
   Project
   Search Index Data Contributor - 8ebe5a00-799e-43f5-93ac-243d3dce84a7
   ------------------------------------------------------------------- */
var searchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'

module roleAssignemntmlWorkspaceHubToSearch 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={

    name: 'roleAssignemntmlWorkspaceHubToSearch'
    
    params: {
      principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: searchIndexDataContributor
      resourceId: searchService.outputs.resourceId
    }

  }
 
  module roleAssignemntmlProjectToSearch 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignemntmlProjectToSearch'

  params: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributor) // Search Index Data Contributor
    principalId:  workspaceProject.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: searchService.outputs.resourceId  
  }
}
 
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

module roleAssignmentSearchToStorage 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentSearchToStorage'

  params: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor) // Search Index Data Contributor
    principalId:  searchService.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}

module roleAssignmentUserToStorage'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name:  'roleAssignmentUserToStorage'

  params: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor) // Search Index Data Contributor
    principalId:  currentUserId
    principalType: 'User'
    resourceId: storageAccount.outputs.resourceId
  }
}
