@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the NAT Gateway')
param natGatewayName string = 'nat-gateway-01'

@description('Name of the public IP address for NAT Gateway')
param publicIpName string = 'pip-natgw-01'

@description('Name of the virtual network')
param vnetName string = 'vnet-main'

@description('Name of the subnet to associate with NAT Gateway')
param subnetName string = 'subnet-private'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Idle timeout in minutes for NAT Gateway')
@minValue(4)
@maxValue(120)
param idleTimeoutInMinutes int = 4

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Development'
  Project: 'NAT-Gateway-Demo'
  Owner: 'DevOps-Team'
}

// Create public IP for NAT Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: idleTimeoutInMinutes
  }
}

// Create NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

// Create virtual network with subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
  }
}

// Outputs
output natGatewayId string = natGateway.id
output natGatewayName string = natGateway.name
output publicIpAddress string = publicIp.properties.ipAddress
output publicIpId string = publicIp.id
output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
