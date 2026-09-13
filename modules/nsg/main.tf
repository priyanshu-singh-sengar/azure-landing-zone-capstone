terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.security_rules : rule.name => rule }

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = lookup(each.value, "source_port_range", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  description                  = lookup(each.value, "description", null)

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
