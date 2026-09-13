terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

# Peering 1: Hub to Spoke (or VNet 1 to VNet 2)
resource "azurerm_virtual_network_peering" "peering_1_to_2" {
  name                         = var.peering_name_1_to_2 != null ? var.peering_name_1_to_2 : "peer-${var.vnet_1_name}-to-${var.vnet_2_name}"
  resource_group_name          = var.vnet_1_rg
  virtual_network_name         = var.vnet_1_name
  remote_virtual_network_id    = var.vnet_2_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = false
}

# Peering 2: Spoke to Hub (or VNet 2 to VNet 1)
resource "azurerm_virtual_network_peering" "peering_2_to_1" {
  name                         = var.peering_name_2_to_1 != null ? var.peering_name_2_to_1 : "peer-${var.vnet_2_name}-to-${var.vnet_1_name}"
  resource_group_name          = var.vnet_2_rg
  virtual_network_name         = var.vnet_2_name
  remote_virtual_network_id    = var.vnet_1_id
  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = false
  use_remote_gateways          = var.use_remote_gateways

  depends_on = [azurerm_virtual_network_peering.peering_1_to_2]
}
