terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

resource "azurerm_public_ip" "gw_pip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = var.type
  vpn_type            = var.vpn_type
  sku                 = var.sku
  enable_bgp          = var.enable_bgp

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gw_pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}
