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

param resourceToken string = ''
 
var unique_searchService_name = empty(searchService_name) ? '${searchService_name}-${resourceToken}' : searchService_name
var unique_cognitiveService_name = empty(cognitiveService_name) ?'${cognitiveService_name}-${resourceToken}' : cognitiveService_name
var unique_workspaces_testaifoundry_name = empty(workspaces_testaifoundry_name) ? '${workspaces_testaifoundry_name}-${resourceToken}' : workspaces_testaifoundry_name
var unique_workspace_testproject_name = empty(workspace_testproject_name) ? '${workspace_testproject_name}-${resourceToken}' : workspace_testproject_name
var unique_projectIdentity_name = 'mi-project-${resourceToken}'

var uniquie_storage_name = 'st${resourceToken}'
 
targetScope = 'resourceGroup'
 

resource rgContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().name, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: currentUserId
    principalType: 'User'
  }
}


module projectIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'hubIdentityDeployment'
  params: {
    name: unique_projectIdentity_name
    location: location
  }
}


/* -------------------------------------------------------------------
   STORAGE ACCOUNT
   ------------------------------------------------------------------- */

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.0' = {
  name: 'storageAccountDeployment'
  params: {

    name: uniquie_storage_name
    
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true //This needs to go back to false
    defaultToOAuthAuthentication: true
    location: location
    blobServices: {
      enabled: true
      containers: [
        {
          name: 'samples'
          publicAccess: 'None'
        }
        {
          name: 'scriptlogs'
          publicAccess: 'None'
        }
      ]
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    roleAssignments: [
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage File Data Privileged Reader'
      }
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: 'Storage File Data Privileged Reader'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
      }

 

    ]
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
    disableLocalAuth: true
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
      {
        model: {
          format: 'OpenAI'
          name: 'gpt-4'
          version: 'turbo-2024-04-09'
        }
        name: 'gpt-4'
        sku: {
          capacity: 10
          name: 'GlobalStandard'
        }
        raiPolicyName: 'Microsoft.DefaultV2'
      }

    ] 
    roleAssignments: [
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Cognitive Services Contributor'
      }
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: '19c28022-e58e-450d-a464-0b2a53034789' //'Cognitive Services Data Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: 'Cognitive Services Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: '19c28022-e58e-450d-a464-0b2a53034789' //'Cognitive Services Data Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: 'a001fd3d-188f-4b5d-821b-7da978bf7442' //'Cognitive Services OpenAI Contributor'
      }
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'a001fd3d-188f-4b5d-821b-7da978bf7442' //'Cognitive Services OpenAI Contributor'
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
      tags: tags
      sku: 'standard'
      
      managedIdentities: {
        userAssignedResourceIds: [
          projectIdentity.outputs.resourceId
        ]
      }
      roleAssignments: [
        {
          principalId: currentUserId
          principalType: 'User'
          roleDefinitionIdOrName: 'Search Index Data Contributor'
        }
        {
          principalId: currentUserId
          principalType: 'User'
          roleDefinitionIdOrName: 'Search Service Contributor'
        }
        {
          principalId: projectIdentity.outputs.principalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Search Index Data Contributor'
        }
        {
          principalId: projectIdentity.outputs.principalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Search Service Contributor'
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Search Index Data Contributor'
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader role
        }
      ]
      replicaCount: 1
      publicNetworkAccess: 'Enabled'
      networkRuleSet: {
        ipRules: []
        bypass: 'None'
      }
      disableLocalAuth: true

      
      semanticSearch: 'standard'
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
      systemAssigned: false
      userAssignedResourceIds: [
        projectIdentity.outputs.resourceId
      ]
    }
    primaryUserAssignedIdentity: projectIdentity.outputs.resourceId
    sku: 'Basic'
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    location: location
    publicNetworkAccess: 'Enabled'
    systemDatastoresAuthMode: 'identity'
    roleAssignments: [
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }
      //add project identity to the workspace
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }
    ]
    connections:[
      {
        category: 'CognitiveSearch'
        name: 'searchService'
        connectionProperties: {
          authType: 'AAD'
        }
        target: searchService.outputs.resourceId
      }
      {
        category: 'AIServices'
        name: 'AIServices'
        isSharedToAll: true
        
        connectionProperties: {
          authType: 'AAD'
        }
        metadata: {
          ApiType: 'Azure'
          ApiVersion: '2023-07-01-preview'
          DeploymentApiVersion: '2023-10-01-preview'
          Location: location
          ResourceId: cognitiveServices.outputs.resourceId
        }

        target: cognitiveServices.outputs.resourceId
      }
    ]
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: resourceGroup().id
    }
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
      userAssignedResourceIds: [
        projectIdentity.outputs.resourceId
      ]
    }
    primaryUserAssignedIdentity: projectIdentity.outputs.resourceId
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }
      //add project identity to the workspace
      {
        principalId: projectIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }


    ]
  }
}





output projectIdentityId string = projectIdentity.outputs.resourceId
