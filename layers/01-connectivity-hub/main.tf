# 1. Hub Resource Group
module "hub_rg" {
  source = "../../modules/resource_group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# 2. Azure Bastion Required NSG
module "bastion_nsg" {
  source = "../../modules/nsg"

  name                = "nsg-hub-bastion"
  location            = var.location
  resource_group_name = module.hub_rg.name

  security_rules = [
    {
      name                       = "AllowHttpsInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Allow inbound HTTPS for browser-to-bastion sessions"
    },
    {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
      description                = "Allow control plane communication from Azure GatewayManager"
    },
    {
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow health probes from Azure Load Balancer"
    },
    {
      name                       = "AllowBastionHostCommunication"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow internal communication between Bastion nodes"
    },
    {
      name                       = "AllowSshRdpOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow outbound SSH and RDP to target VMs in VNets"
    },
    {
      name                       = "AllowAzureCloudOutbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
      description                = "Allow outbound to Azure Cloud management endpoints"
    },
    {
      name                       = "AllowBastionCommunicationOutbound"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow outbound inter-node communication for Bastion"
    },
    {
      name                       = "AllowGetSessionInformation"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
      description                = "Allow outbound session information lookup"
    }
  ]

  tags = var.tags
}

# 2b. Shared Services Subnet NSG
# Network security group for shared services subnet to allow VNet internal traffic and block direct internet ingress.
module "shared_svc_nsg" {
  source = "../../modules/nsg"

  name                = "nsg-hub-shared-svc"
  location            = var.location
  resource_group_name = module.hub_rg.name

  security_rules = [
    {
      name                       = "AllowVNetInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
      description                = "Allow internal traffic within Virtual Network"
    },
    {
      name                       = "DenyInternetInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Explicitly block all direct inbound Internet traffic"
    }
  ]

  tags = var.tags
}

# 3. Hub Virtual Network with Dedicated Subnets
module "hub_vnet" {
  source = "../../modules/vnet"

  name                = var.vnet_name
  location            = var.location
  resource_group_name = module.hub_rg.name
  address_space       = var.vnet_address_space

  subnets = {
    GatewaySubnet = {
      address_prefixes = [var.gateway_subnet_cidr]
    }
    AzureBastionSubnet = {
      address_prefixes = [var.bastion_subnet_cidr]
    }
    AzureFirewallSubnet = {
      address_prefixes = [var.firewall_subnet_cidr]
    }
    AzureFirewallManagementSubnet = {
      address_prefixes = [var.firewall_mgmt_subnet_cidr]
    }
    snet-shared-svc = {
      address_prefixes = [var.shared_svc_subnet_cidr]
    }
  }

  subnet_nsg_ids = {
    AzureBastionSubnet = module.bastion_nsg.id
    snet-shared-svc    = module.shared_svc_nsg.id
  }

  tags = var.tags
}

# 4. Azure Firewall
module "azure_firewall" {
  source = "../../modules/azure_firewall"

  name                          = var.firewall_name
  location                      = var.location
  resource_group_name           = module.hub_rg.name
  sku_tier                      = var.firewall_sku_tier
  firewall_subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"]
  firewall_management_subnet_id = module.hub_vnet.subnets["AzureFirewallManagementSubnet"]
  enable_dns_proxy              = true
  tags                          = var.tags
}

# 5. Azure Bastion Host
module "bastion" {
  source = "../../modules/bastion"

  name                = var.bastion_name
  location            = var.location
  resource_group_name = module.hub_rg.name
  sku                 = var.bastion_sku
  bastion_subnet_id   = module.hub_vnet.subnets["AzureBastionSubnet"]
  tunneling_enabled   = true
  tags                = var.tags
}

# 6. Virtual Network Gateway (VPN / ExpressRoute) - Optional Toggle for Cost Control
module "vpn_gateway" {
  count  = var.enable_vpn_gateway ? 1 : 0
  source = "../../modules/vpn_gateway"

  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = module.hub_rg.name
  gateway_subnet_id   = module.hub_vnet.subnets["GatewaySubnet"]
  sku                 = var.vpn_gateway_sku
  type                = "Vpn"
  vpn_type            = "RouteBased"
  enable_bgp          = false
  tags                = var.tags
}
