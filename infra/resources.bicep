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
var unique_scriptingIdentity_name = 'mi-scripting-${resourceToken}'
var uniquie_storage_name = 'st${resourceToken}'
 
targetScope = 'resourceGroup'
 
module scriptingIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'scriptingIdentityDeployment'
  params: {
    name: unique_scriptingIdentity_name
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
        principalId: scriptingIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
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
      roleAssignments: [
        {
          principalId: scriptingIdentity.outputs.principalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Search Service Contributor'
        }
        {
          principalId: scriptingIdentity.outputs.principalId
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Search Index Data Contributor'
        }
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
      ]
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
    systemDatastoresAuthMode: 'identity'
    roleAssignments: [
      {
        principalId: currentUserId
        principalType: 'User'
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }
    ]
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
        roleDefinitionIdOrName: '3afb7f49-54cb-416e-8c09-6dc049efa503' // 'Azure AI Inference Deployment Operator'
      }
    ]
  }
}


/* -------------------------------------------------------------------
   Managed Identitiy ROLE ASSIGNMENT
   Hub
   Project
   Search Index Data Contributor - 8ebe5a00-799e-43f5-93ac-243d3dce84a7
   ------------------------------------------------------------------- */
var searchIndexDataContributor = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchServiceContributor = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageBlobDataReader = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var storageFileDataPrivilegedReader = 'b8eda974-7b85-4f76-af95-65846b26df6d'

module HubToSearchService 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: 'HubToSearchServiceRole'
  params: {
    principalId: mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: searchServiceContributor// Search Index Data Contributor
    resourceId: searchService.outputs.resourceId
  }
}


module ProjectToSearchService 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: 'ProjectToSearchServiceRole'
  params: {
    principalId: workspaceProject.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: searchServiceContributor// Search Index Data Contributor
    resourceId: searchService.outputs.resourceId
  }
}


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
    roleDefinitionId: searchIndexDataContributor // Search Index Data Contributor
    principalId:  workspaceProject.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: searchService.outputs.resourceId  
  }
}

 


module roleAssignmentSearchToStorage 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentSearchToStorage'

  params: {
    roleDefinitionId: storageBlobDataContributor // Search Index Data Contributor
    principalId:  searchService.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}


module roleAssignmentHubToStorage 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentHubToStorage'

  params: {
    roleDefinitionId: storageBlobDataReader // Search Index Data Contributor
    principalId:  mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}
module roleAssignmentProjectToStorage 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentProjectToStorage'

  params: {
    roleDefinitionId: storageBlobDataReader // Search Index Data Contributor
    principalId:  workspaceProject.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}

//hub and project get storageFileDataPriv reader on the storage account
module roleAssignmentHubToStorageFileDataPrivilegedReader 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentHubToStorFileDataPrivRea'

  params: {
    roleDefinitionId: storageFileDataPrivilegedReader // Search Index Data Contributor
    principalId:  mlWorkspaceHub.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}
module roleAssignmentProjectToStorageFileDataPrivilegedReader 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' ={
  name: 'roleAssignmentProjectToStorFileDataPrivRdr'

  params: {
    roleDefinitionId: storageFileDataPrivilegedReader // Search Index Data Contributor
    principalId:  workspaceProject.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    resourceId: storageAccount.outputs.resourceId
  }
}


module uploadBlobsScript 'br/public:avm/res/resources/deployment-script:0.5.0' = {
  name: 'uploadBlobsScriptDeployment'
  params: {
    kind: 'AzurePowerShell'
    name: 'pwscript-uploadBlobsScript'
    azPowerShellVersion: '12.3'
    location: location
    
    managedIdentities: {
      userAssignedResourceIds: [
        scriptingIdentity.outputs.resourceId
      ]
    }
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    enableTelemetry: true
    storageAccountResourceId: storageAccount.outputs.resourceId
    arguments: '-StorageAccountName ${storageAccount.outputs.name} -SearchServiceName ${searchService.outputs.name}' //multi line strings do not support interpolation in bicep yet
    scriptContent: '''
      param(
          [string] $StorageAccountName,
          [string] $SearchServiceName
      )
      
      # Validate Parameters
      if ($StorageAccountName -eq $null) {
          throw "Storage Account is not supplied as a parameter"
      }
      if ($SearchServiceName -eq $null) {
          throw "Search Service Name is not supplied as a parameter"
      }
      
      try {
          # Upload Documents to Azure Storage
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rob-foulkrod/aihubs/refs/heads/main/data/hotels/HotelsData_toAzureSearch.JSON" -OutFile HotelsData_toAzureSearch.JSON -UseBasicParsing
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rob-foulkrod/aihubs/refs/heads/main/data/hotels/HotelsData_toAzureSearch.csv" -OutFile HotelsData_toAzureSearch.csv -UseBasicParsing
          Invoke-WebRequest -Uri "https://raw.githubusercontent.com/rob-foulkrod/aihubs/refs/heads/main/data/hotels/Hotels_IndexDefinition.JSON" -OutFile Hotels_IndexDefinition.JSON -UseBasicParsing
      
          $context = New-AzStorageContext -StorageAccountName $StorageAccountName
      
          # samples container is precreated in the storage bicep resource
          Set-AzStorageBlobContent -Context $context -Container "samples" -File HotelsData_toAzureSearch.JSON -Blob HotelsData_toAzureSearch.JSON -Force
          Set-AzStorageBlobContent -Context $context -Container "samples" -File HotelsData_toAzureSearch.csv -Blob HotelsData_toAzureSearch.csv -Force
          Set-AzStorageBlobContent -Context $context -Container "samples" -File Hotels_IndexDefinition.JSON -Blob Hotels_IndexDefinition.JSON -Force
      
          

          # Search Get Access Token
          $access_token = (Get-AzAccessToken -ResourceUrl "https://search.azure.com").Token
      
          # throw exception of the access token is not retrieved
          if ($access_token -eq $null) {
              throw "Failed to retrieve access token"
          }


          # Create Index
          $uri = "https://$SearchServiceName.search.windows.net/indexes?api-version=2024-07-01"
          $body = Get-Content -Path './Hotels_IndexDefinition.JSON' -Raw

          $maxRetries = 3
          $retryCount = 0
          $success = $false
      
          while (-not $success -and $retryCount -lt $maxRetries) {
              try {
                  $response = Invoke-RestMethod -Uri $uri -Method 'POST' -Body $body -Headers @{Authorization="Bearer $access_token"} -ContentType "application/json"
                  $success = $true
              } catch {
                  $retryCount++
                  Write-Host "Attempt $retryCount failed. Retrying..."
                  Start-Sleep -Seconds 2
              }
          }
      
          if (-not $success) {
              throw "Failed to create index after $maxRetries attempts."
          }


          # Upload Data to Index
          $uri = "https://$SearchServiceName.search.windows.net/indexes/hotels/docs/index?api-version=2024-07-01"
          $body = Get-Content -Path HotelsData_toAzureSearch.JSON -Raw
      
          $maxRetries = 3
          $retryCount = 0
          $success = $false
      
          while (-not $success -and $retryCount -lt $maxRetries) {
              try {
                  $response = Invoke-RestMethod -Uri $uri -Method 'POST' -Body $body -Headers @{Authorization="Bearer $access_token"} -ContentType "application/json"
                  $success = $true
              } catch {
                  $retryCount++
                  Write-Host "Attempt $retryCount failed. Retrying..."
                  Start-Sleep -Seconds 2
              }
          }
      
          if (-not $success) {
              throw "Failed to upload data to index after $maxRetries attempts."
          }
      

      } catch {
          Write-Host "An error occurred: $_"
          throw
      }
      '''
  }
}
