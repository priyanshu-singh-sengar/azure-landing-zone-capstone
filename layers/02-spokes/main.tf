# 1. Spoke Resource Group
module "spoke_rg" {
  source = "../../modules/resource_group"

  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# 2. Tier NSGs: Microsegmentation (Web, App, Data tiers)
module "web_nsg" {
  source = "../../modules/nsg"

  name                = "nsg-${var.environment}-web"
  location            = var.location
  resource_group_name = module.spoke_rg.name

  security_rules = [
    {
      name                       = "AllowHttpInbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow inbound HTTP from perimeter/Application Gateway"
    },
    {
      name                       = "AllowHttpsInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow inbound HTTPS from perimeter/Application Gateway"
    },
    {
      name                       = "DenyDataDirectAccess"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = var.data_subnet_cidr
      destination_address_prefix = "*"
      description                = "Deny direct inbound traffic initiated from Database subnet"
    }
  ]

  tags = var.tags
}

module "app_nsg" {
  source = "../../modules/nsg"

  name                = "nsg-${var.environment}-app"
  location            = var.location
  resource_group_name = module.spoke_rg.name

  security_rules = [
    {
      name                       = "AllowInboundFromWeb"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "8443", "5000"]
      source_address_prefix      = var.web_subnet_cidr
      destination_address_prefix = "*"
      description                = "Allow application traffic strictly from Web subnet"
    },
    {
      name                       = "AllowBastionSshRdpInbound"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "10.0.2.0/26" # AzureBastionSubnet
      destination_address_prefix = "*"
      description                = "Allow administrative access from Hub Azure Bastion"
    },
    {
      name                       = "DenyDirectInternetInbound"
      priority                   = 400
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny all direct inbound traffic from Internet"
    }
  ]

  tags = var.tags
}

module "db_nsg" {
  source = "../../modules/nsg"

  name                = "nsg-${var.environment}-db"
  location            = var.location
  resource_group_name = module.spoke_rg.name

  security_rules = [
    {
      name                       = "AllowInboundFromApp"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["1433", "5432", "3306"]
      source_address_prefix      = var.app_subnet_cidr
      destination_address_prefix = "*"
      description                = "Allow SQL/DB traffic strictly from Application subnet"
    },
    {
      name                       = "DenyDirectWebInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = var.web_subnet_cidr
      destination_address_prefix = "*"
      description                = "Deny direct traffic bypassing App tier from Web tier"
    },
    {
      name                       = "DenyDirectInternetInbound"
      priority                   = 400
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Deny all inbound traffic from Internet to Database"
    }
  ]

  tags = var.tags
}

# 3. User-Defined Route (UDR) Table: Force 0.0.0.0/0 via Azure Firewall
module "spoke_route_table" {
  source = "../../modules/route_table"

  name                = "rt-${var.environment}-spoke-01"
  location            = var.location
  resource_group_name = module.spoke_rg.name

  routes = [
    {
      name                   = "udr-default-to-hub-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub_firewall_private_ip
    }
  ]

  tags = var.tags
}

# 4. Spoke Virtual Network and Subnets
module "spoke_vnet" {
  source = "../../modules/vnet"

  name                = var.vnet_name
  location            = var.location
  resource_group_name = module.spoke_rg.name
  address_space       = var.vnet_address_space

  subnets = {
    snet-web = {
      address_prefixes = [var.web_subnet_cidr]
    }
    snet-app = {
      address_prefixes = [var.app_subnet_cidr]
    }
    snet-db = {
      address_prefixes = [var.data_subnet_cidr]
    }
    snet-pe = {
      address_prefixes = [var.pe_subnet_cidr]
    }
  }

  subnet_nsg_ids = {
    snet-web = module.web_nsg.id
    snet-app = module.app_nsg.id
    snet-db  = module.db_nsg.id
  }

  subnet_route_table_ids = {
    snet-web = module.spoke_route_table.id
    snet-app = module.spoke_route_table.id
    snet-db  = module.spoke_route_table.id
  }

  tags = var.tags
}

# 5. Bi-Directional VNet Peering with Hub
module "peering" {
  count  = var.enable_peering ? 1 : 0
  source = "../../modules/vnet_peering"

  vnet_1_name = var.hub_vnet_name
  vnet_1_id   = var.hub_vnet_id
  vnet_1_rg   = var.hub_resource_group_name

  vnet_2_name = module.spoke_vnet.name
  vnet_2_id   = module.spoke_vnet.id
  vnet_2_rg   = module.spoke_rg.name

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = var.use_remote_gateways
}

# 6. Optional Validation VM in App Subnet (Zero Public IP)
resource "azurerm_network_interface" "test_nic" {
  count               = var.enable_test_vm ? 1 : 0
  name                = "nic-${var.environment}-test-01"
  location            = var.location
  resource_group_name = module.spoke_rg.name

  ip_configuration {
    name                          = "ipconfig-internal"
    subnet_id                     = module.spoke_vnet.subnets["snet-app"]
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "test_vm" {
  count                           = var.enable_test_vm ? 1 : 0
  name                            = "vm-${var.environment}-test01"
  location                        = var.location
  resource_group_name             = module.spoke_rg.name
  size                            = var.test_vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.test_nic[0].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}
