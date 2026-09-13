terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = lookup(each.value, "service_endpoints", null)
  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", true)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = lookup(delegation.value.service_delegation, "actions", null)
      }
    }
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = var.subnet_nsg_ids

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value
}

# Route Table Associations
resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = var.subnet_route_table_ids

  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = each.value
}
