//param keyVaultName string
param containerRegistryName string
param containerRegistryImageName string
param containerRegistryImageVersion string = 'main-latest'
param ServicePlanName string
param webAppName string
param location string = resourceGroup().location


//param kevVaultSecretNameACRUsername string = 'acr-username'
//param kevVaultSecretNameACRPassword1 string = 'acr-password1'
//param kevVaultSecretNameACRPassword2 string = 'acr-password2'

param DOCKER_REGISTRY_SERVER_USERNAME string
param DOCKER_REGISTRY_SERVER_URL string
@secure()
param DOCKER_REGISTRY_SERVER_PASSWORD string


//resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  //name: keyVaultName
//}
// Deploy Azure Container Registry

module containerRegistry 'modules/container-registry/registry/main.bicep' = {
  //dependsOn: [
    //keyvault
  //]
  name: containerRegistryName
  params: {
    name: containerRegistryName
    location: location
    acrAdminUserEnabled: true

    //adminCredentialsKeyVaultResourceId: resourceId('Microsoft.KeyVault/vaults', keyVaultName)
    //adminCredentialsKeyVaultSecretUserName: kevVaultSecretNameACRUsername
    //adminCredentialsKeyVaultSecretPassword1: kevVaultSecretNameACRPassword1
    //adminCredentialsKeyVaultSecretPassword2: kevVaultSecretNameACRPassword2
  }
}

module serverfarm 'modules/web/serverfarm/main.bicep' = {
  name: ServicePlanName
  params: {
    name: ServicePlanName
    location: location
    sku: {
      capacity: 1
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
      kind: 'Linux'
    }
    reserved: true
  }
}

module website 'modules/web/site/main.bicep' =  {
  dependsOn: [
    serverfarm
    containerRegistry
    //keyvault
  ]
  name: webAppName
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: resourceId('Microsoft.Web/serverfarms', ServicePlanName)
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerRegistryImageName}:latest'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
      DOCKER_REGISTRY_SERVER_URL: DOCKER_REGISTRY_SERVER_URL
      DOCKER_REGISTRY_SERVER_USERNAME:  DOCKER_REGISTRY_SERVER_USERNAME
      DOCKER_REGISTRY_SERVER_PASSWORD: DOCKER_REGISTRY_SERVER_PASSWORD
    }
  }
}
