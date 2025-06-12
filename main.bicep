@description('Name of the NAT Gateway')
param natGatewayName string = 'NatGateway01'
@description('Location for the resources')
param location string = resourceGroup().location
@description('Name of the public IP address')
param publicIpName string = 'pip-natgw'
@description('Name of the virtual network')
param vnetName string
@description('Name of the subnet to associate with the NAT Gateway')
param subnetName string
@description('Username for VM')
param adminUsername string
@secure()
@description('Password for VM')
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

// Update Subnet with NAT Gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: '10.0.0.0/24' // Adjust to match your VNet subnet if needed
    natGateway: {
      id: natGateway.id
    }
  }
}

// Create Network Interface for VM
resource nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'vm-nic'
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

// Create Windows VM
resource winVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'winvm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'winvm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
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
}
