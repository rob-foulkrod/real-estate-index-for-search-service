targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param currentUserId string

var tags = {
  'azd-env-name': environmentName
}
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module resources './resources.bicep' = {
  name: 'resources'
  scope: rg
  params: {
    resourceToken: resourceToken
    currentUserId: currentUserId
    tags: tags
    location: location
    searchService_name: 'search-${resourceToken}'
    cognitiveService_name: 'cog-${resourceToken}'
    workspaces_testaifoundry_name: 'hub-${resourceToken}'
    workspace_testproject_name: 'project-${resourceToken}'
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'rg-roleassignment-deployment'
  properties: {
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor role
    principalId: resources.outputs.projectIdentityId
  }
}
