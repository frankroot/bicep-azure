param resourceName string = 'crashell'
param location string = resourceGroup().location
param adminUsername string
param adminPassword string

var vmSize            = 'Standard_B1s'
var vnetName          = '${resourceName}-vnet'
var vnetAddress       = '10.0.0.0/16'
var vnetSubnetName    = 'public'
var vnetSubnetAddress = '10.0.0.0/24'
var vmName            = '${resourceName}-vm'
var pipName           = '${resourceName}-ip'
var nicName           = '${resourceName}-nic'
var nsgName           = '${resourceName}-nsg'
var envTag            = 'dev'

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = { 
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
  tags: {
    env: envTag
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
  tags: {
    env: envTag
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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
        name: vnetSubnetName
        properties: {
          addressPrefix: vnetSubnetAddress
        }
      }
    ]
  }
  tags: {
    env: envTag
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, vnetSubnetName)
          }
        }
      }
    ]
  }
  tags: {
    env: envTag
  }
  dependsOn: [
    vnet
    nsg
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-hirsute'
        sku: '21_04-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: {
    env: envTag
  }
}

output ip string = pip.properties.ipAddress
