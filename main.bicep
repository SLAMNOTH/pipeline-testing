@description('Name of the NAT Gateway')
param natGatewayName string = 'NatGateway01'

@description('Location for the resources')
param location string = resourceGroup().location

@description('Name of the public IP address for NAT Gateway')
param publicIpName string = 'pip-natgw'

@description('Name of the virtual network')
param vnetName string

@description('Name of the subnet to associate with the NAT Gateway')
param subnetName string

@description('Name of the VM')
param vmName string = 'winvm-nat'

@description('Size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Admin username for the VM')
param adminUsername string

@minLength(12)
@secure()
@description('Admin password for the VM')
param adminPassword string

// Create a Public IP for NAT Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create the NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
    idleTimeoutInMinutes: 10
  }
}

// Reference existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

// Update subnet to associate it with NAT Gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: '10.0.0.0/24' // Replace as needed
    natGateway: {
      id: natGateway.id
    }
  }
}

// Network Interface for the VM
var nicName = '${vmName}-nic'

resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Windows VM
resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
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
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
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
}
