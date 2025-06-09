@description('VM admin username')
param adminUsername string

@description('SSH public key')
param sshPublicKey string

@description('VM name')
param vmName string = 'testvm'

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: 'WestEurope'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ls'  // Cheapest VM ($4-5/month)
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [{
            path: '/home/${adminUsername}/.ssh/authorized_keys'
            keyData: sshPublicKey
          }]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [{
        id: nic.id
      }]
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-03-01' = {
  name: '${vmName}-nic'
  location: 'WestEurope'
  properties: {
    ipConfigurations: [{
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        publicIPAddress: {
          id: publicIp.id
        }
        subnet: {
          id: vnet::subnet.id
        }
      }
    }]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-03-01' = {
  name: '${vmName}-ip'
  location: 'WestEurope'
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-03-01' existing = {
  name: 'default-vnet'
}

