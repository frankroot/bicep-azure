@description('Nombre de la aplicación o proyecto - Prefijo para el nombre de los recursos')
param projectName string = 'crashell'

@description('Región para crear los recursos')
param location string = resourceGroup().location

var nameBastion           = '${projectName}-bastion'
var vnetName              = '${projectName}-vnet'
var vnetAddress           = '10.0.0.0/16'
var subnet1Name           = 'subnet1'
var subnet2Name           = 'subnet2'
var subnet1Address        = '10.0.1.0/24'
var subnet2Adress         = '10.0.2.0/24'
var subnetBastion         = 'AzureBastionSubnet'
var subnetBastionAddress  = '10.0.3.0/27'
var pipName               = '${projectName}-ip'
var envTag                = 'dev'

resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = { 
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'crashell'
    }
  }
  sku: {
    name: 'Standard'
  }
  tags: {
    name: projectName
    env: envTag
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Address
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Adress
        }
      }
      {
        name: subnetBastion
        properties: {
          addressPrefix: subnetBastionAddress
        }
      }
    ]
  }
  tags: {
    name: projectName
    env: envTag
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: nameBastion
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetBastion)
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
  tags: {
    name: projectName
    env: envTag
  }
}
