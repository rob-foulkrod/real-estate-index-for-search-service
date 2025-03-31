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
      disableLocalAuth: false
      authOptions: {
        aadOrApiKey: {
          aadAuthFailureMode: 'http401WithBearerChallenge'
        }
      }
      
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

module uploadBlobsScript 'br/public:avm/res/resources/deployment-script:0.5.0' = {
  name: 'uploadBlobsScriptDeployment'
  params: {
    kind: 'AzurePowerShell'
    name: 'pwscript-uploadBlobsScript'
    azPowerShellVersion: '12.3'
    location: location
    
    managedIdentities: {
      userAssignedResourceIds: [
        projectIdentity.outputs.resourceId
      ]
    }

    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    enableTelemetry: true
    storageAccountResourceId: storageAccount.outputs.resourceId
    arguments: '-StorageAccountName ${storageAccount.outputs.name} -SearchServiceName ${searchService.outputs.name} -ProjectName ${unique_cognitiveService_name} -ServicePrincipalResourceId ${projectIdentity.outputs.resourceId} ' //multi line strings do not support interpolation in bicep yet

    scriptContent: '''
      param(
          [string] $StorageAccountName,
          [string] $SearchServiceName,
          [string] $ProjectName,
          [string] $ServicePrincipalResourceId
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

          echo "Access Token retrieved successfully"


          # replace the <projectName> placeholder in the index definition with the project name
          $indexDefinition = Get-Content -Path './Hotels_IndexDefinition.JSON' -Raw

          echo "Index Definition before replacement:"
          echo $indexDefinition
          echo ''


          $indexDefinition = $indexDefinition -replace '<projectName>', $ProjectName
          Set-Content -Path './Hotels_IndexDefinition.JSON' -Value $indexDefinition

          #replace the <servicePrincipalId> placeholder in the index definition with the service principal id
          $indexDefinition = Get-Content -Path './Hotels_IndexDefinition.JSON' -Raw 
          $indexDefinition = $indexDefinition -replace '<servicePrincipalResourceId>', $ServicePrincipalResourceId
          Set-Content -Path './Hotels_IndexDefinition.JSON' -Value $indexDefinition
          
          echo "Index Definition after replacement:"
          echo $indexDefinition
          echo ''


          # Create Index
          $uri = "https://$SearchServiceName.search.windows.net/indexes?api-version=2024-11-01-preview"
          $body = Get-Content -Path './Hotels_IndexDefinition.JSON' -Raw

          $maxRetries = 3
          $retryCount = 0
          $success = $false
      
          while (-not $success -and $retryCount -lt $maxRetries) {
              $response = ''
              try {
                  $response = Invoke-RestMethod -Uri $uri -Method 'POST' -Body $body -Headers @{Authorization="Bearer $access_token"} -ContentType "application/json"
                  echo $response
                  $success = $true
              } catch {
                  $retryCount++
                  Write-Host "Attempt $retryCount failed"
                  Write-Host "Response: $response"
                  Write-Host "Error: $_"
                  Write-Host "Retrying in 2 seconds..."
                  Start-Sleep -Seconds 2
              }
          }
      
          if (-not $success) {
              throw "Failed to create index after $maxRetries attempts."
          }




          # Upload Data to Index
          $uri = "https://$SearchServiceName.search.windows.net/indexes/hotels/docs/index?api-version=2024-11-01-preview"
          $body = Get-Content -Path HotelsData_toAzureSearch.JSON -Raw
      
          $maxRetries = 3
          $retryCount = 0
          $success = $false
      
          while (-not $success -and $retryCount -lt $maxRetries) {
              $response = ''
              try {
                  $response = Invoke-RestMethod -Uri $uri -Method 'POST' -Body $body -Headers @{Authorization="Bearer $access_token"} -ContentType "application/json"
                  echo $response  
                  echo "Data uploaded successfully"
                  $success = $true
              } catch {
                  $retryCount++
                  Write-Host "Attempt $retryCount failed."
                  Write-Host "Response: $response"
                  Write-Host "Error: $_"
                  Write-Host "Retrying in 2 seconds..."
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
  dependsOn: [
    cognitiveServices
  ]
}

output projectIdentityId string = projectIdentity.outputs.resourceId
