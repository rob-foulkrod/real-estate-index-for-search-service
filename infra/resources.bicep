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
var uniquie_storage_name = 'st${resourceToken}'
 
targetScope = 'resourceGroup'


var roleStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var roleStorageFileDataPrivilegedReader = 'b8eda974-7b85-4f76-af95-65846b26df6d'
var roleStorageFileDataPrivilegedContributor = '69566ab7-960f-475b-8e7c-b3118f30c6bd'
var roleStorageTableDataContributor = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

var roleSearchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var roleSearchIndexDataReader = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var roleSearchServiceContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var roleCognitiveServicesContributor = '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68'
var roleCognitiveServicesDataContributor = '19c28022-e58e-450d-a464-0b2a53034789'
var roleCognitiveServicesOpenAIContributor = 'a001fd3d-188f-4b5d-821b-7da978bf7442'
var roleAzureAIInferenceDeploymentOperator = '3afb7f49-54cb-416e-8c09-6dc049efa503'
var roleReader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

/* -------------------------------------------------------------------
   STORAGE ACCOUNT
   ------------------------------------------------------------------- */

module storageAccount 'br/public:avm/res/storage/storage-account:0.18.0' = {
  name: 'storageAccountDeployment'
  params: {

    name: uniquie_storage_name
    
    allowBlobPublicAccess: true
    allowSharedKeyAccess: false //This needs to go back to false
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
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleStorageBlobDataContributor
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleStorageFileDataPrivilegedContributor
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
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleCognitiveServicesContributor
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleCognitiveServicesDataContributor //'Cognitive Services Data Contributor'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleCognitiveServicesOpenAIContributor //'Cognitive Services OpenAI Contributor'
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
        systemAssigned: true
      }
      
      roleAssignments: [
        {
          principalId: currentUserId
          principalType: 'User'
          roleDefinitionIdOrName: roleSearchServiceContributor
        }
        {
          principalId: currentUserId
          principalType: 'User'
          roleDefinitionIdOrName: roleSearchIndexDataContributor
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: roleSearchIndexDataContributor
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: roleSearchIndexDataReader
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: roleSearchServiceContributor
        }
        {
          principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: roleReader
        }

      ]
      replicaCount: 1
      publicNetworkAccess: 'Enabled'
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
      systemAssigned: true
    }
    sku: 'Basic'
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    location: location
    publicNetworkAccess: 'Enabled'
    systemDatastoresAuthMode: 'identity'
    roleAssignments: [
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleAzureAIInferenceDeploymentOperator // 'Azure AI Inference Deployment Operator'
      }
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleCognitiveServicesOpenAIContributor // 'Cognitive Services OpenAI Contributor'
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
      systemAssigned: true
    }
    
    publicNetworkAccess: 'Enabled'
    roleAssignments: [
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: roleAzureAIInferenceDeploymentOperator // 'Azure AI Inference Deployment Operator'
      }
      //add project identity to the workspace
      {
        principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: roleAzureAIInferenceDeploymentOperator // 'Azure AI Inference Deployment Operator'
      }


    ]
  }
}

resource rgContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().name, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: currentUserId
    principalType: 'User'
  }
}


//-----------
// RBAC Assignment on the Storage Account [Storage Blob Data Contributor, Storage File Data Privileged Reader, Storage Table Data Contributor]
//-----------

// alread applied
// module hubBlobDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   name: 'hubBlobDataContribAssignmentDeployment'
//   params: {
//     // Required parameters
//     principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
//     resourceId: storageAccount.outputs.resourceId
//     roleDefinitionId: roleStorageBlobDataContributor
//   }
// }

// module projectBlobDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   name: 'projectBlobDataContribAssignmentDeployment'
//   params: {
//     // Required parameters
//     principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
//     resourceId: storageAccount.outputs.resourceId
//     roleDefinitionId: roleStorageBlobDataContributor
//   }
// }
module searchBlobDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'searchBlobDataContribAssignmentDeployment'
  params: {
    // Required parameters
    principalId: searchService.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageBlobDataContributor
  }
}

module cogStorageBlobDataContribAssignment'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'cogStorageBlobDataContribAssignment'
  params: {
    // Required parameters
    principalId: cognitiveServices.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageBlobDataContributor
  }
}

//Storage File Data Privileged Reader on the Storage Account
module hubFileDataPrivReaderAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubFileDataPrivReaderAssignmentDeployment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageFileDataPrivilegedReader
  }
}

module projectFileDataPrivReaderAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectFileDataPrivReaderAssignmentDeployment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageFileDataPrivilegedReader
  }
}

module searchFileDataPrivReaderAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'searchFileDataPrivReaderAssignmentDeployment'
  params: {
    // Required parameters
    principalId: searchService.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageFileDataPrivilegedReader
  }
}

//Storage Table Data Contributor on the Storage Account
module hubTableDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubTableDataContribAssignmentDeployment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageTableDataContributor
  }
}

// module projectTableDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   name: 'projectTableDataContribAssignmentDeployment'
//   params: {
//     // Required parameters
//     principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
//     resourceId: storageAccount.outputs.resourceId
//     roleDefinitionId: roleStorageTableDataContributor
//   }
// }

module searchTableDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'searchTableDataContribAssignmentDeployment'
  params: {
    // Required parameters
    principalId: searchService.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.outputs.resourceId
    roleDefinitionId: roleStorageTableDataContributor
  }
}

//-----------
// RBAC Assignment on the Search Service [Search Index Data Contributor, Search Service Contributor]
//-----------

module hubIndexDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubIndexDataContribAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: searchService.outputs.resourceId
    roleDefinitionId: roleSearchIndexDataContributor
  }
}

module projectIndexDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectIndexDataContribAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: searchService.outputs.resourceId
    roleDefinitionId: roleSearchIndexDataContributor
  }
}

module hubSearchServiceContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubSearchServiceContribAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: searchService.outputs.resourceId
    roleDefinitionId: roleSearchServiceContributor
  }
}

module projectSearchServiceContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectSearchServiceContribAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: searchService.outputs.resourceId
    roleDefinitionId: roleSearchServiceContributor
  }
}

//-----------
// RBAC Assignment on the Cognitive Services [Cognitive Services Contributor, Cognitive Services Data Contributor, Cognitive Services OpenAI Contributor, Azure AI Inference Deployment Operator]
//-----------


module hubCognitiveServicesContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubCognitiveServicesContribAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesContributor
  }
}

module projectCognitiveServicesContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectCognitiveServicesContribAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesContributor
  }
}


module hubCognitiveServicesDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubCognitiveServicesDataContribAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesDataContributor //'Cognitive Services Data Contributor'
  }
}

module projectCognitiveServicesDataContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectCognitiveServicesDataContribAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesDataContributor //'Cognitive Services Data Contributor'
  }
}

module hubCognitiveServicesOpenAIContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubCognitiveServicesOpenAIContribAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesOpenAIContributor //'Cognitive Services OpenAI Contributor'
  }
}

module projectCognitiveServicesOpenAIContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectCognitiveServicesOpenAIContribAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesOpenAIContributor //'Cognitive Services OpenAI Contributor'
  }
}

module searchCognitiveServicesOpenAIContribAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'searchCognitiveServicesOpenAIContribAssignment'
  params: {
    // Required parameters
    principalId: searchService.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleCognitiveServicesOpenAIContributor //'Azure AI Inference Deployment Operator'
  }
}

module hubAIInferenceDeploymentOperatorAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'hubAIInferenceDeploymentOperatorAssignment'
  params: {
    // Required parameters
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleAzureAIInferenceDeploymentOperator //'Azure AI Inference Deployment Operator'
  }
}



module projectAIInferenceDeploymentOperatorAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'projectAIInferenceDeploymentOperatorAssignment'
  params: {
    // Required parameters
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    resourceId: cognitiveServices.outputs.resourceId
    roleDefinitionId: roleAzureAIInferenceDeploymentOperator //'Azure AI Inference Deployment Operator'
  }
}







