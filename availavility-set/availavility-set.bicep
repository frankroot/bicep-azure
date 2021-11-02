@description('Nombre de la aplicación o proyecto - Prefijo para el nombre de los recursos')
param resourceName string = 'crashell'

@description('Región para crear los recursos')
param location string = resourceGroup().location

@description('Cantidad de máquinas virtuales a crear')
param numberVM int = 4

@description('Sistema Operativo (Windows o Ubuntu)')
param sistemaOperativo string = 'Ubuntu'

@description('Nombre de usuario para las máquinas virtuales')
param adminUsername string

@description('Contraseña para las máquinas virtuales')
param adminPassword string

var imageReference = {
  Ubuntu: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-hirsute'
    sku: '21_04-gen2'
    version: 'latest'
  }
  Windows: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter'
    version: 'latest'
  }
}

var avSetName       = '${resourceName}-avset'
var vnetName        = '${resourceName}-vnet'
var vnetAddress     = '10.0.0.0/16'
var subnet1Name     = 'subnet1'
var subnet2Name     = 'subnet2'
var subnet1Address  = '10.0.1.0/24'
var subnet2Adress   = '10.0.2.0/24'
var subnet1Ref      = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet1Name)
var subnet2Ref      = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet2Name)
var vmName          = '${resourceName}-vm'
var vmSize          = 'Standard_B1s'
var nicName         = '${resourceName}-nic'
var envTag          = 'dev'

resource availavilitySet 'Microsoft.Compute/availabilitySets@2021-07-01' = {
  name: avSetName
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
  sku: {
    name: 'Aligned'
  }
  tags: {
    Name: resourceName
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
    ]
  }
  tags: {
    Name: resourceName
    env: envTag
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = [for i in range(0, numberVM): {
  name: '${nicName}-${i}'
  location: location
  properties: {
    ipConfigurations: [ 
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: (((i % 2) == 0) ? subnet1Ref : subnet2Ref) 
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet
  ]
  tags: {
    Name: resourceName
    env: envTag
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(0, numberVM): {
  name: '${vmName}-${i}'
  location: location
  properties: {
    availabilitySet: {
      id: availavilitySet.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'VM-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageReference[sistemaOperativo]
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName}-${i}')
        }
      ]
    }
  }
  dependsOn: [
    availavilitySet
    nic
  ]
  tags: {
    Name: resourceName
    env: envTag
  }
}]
