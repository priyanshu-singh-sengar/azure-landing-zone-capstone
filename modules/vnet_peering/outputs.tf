output "peering_1_to_2_id" {
  value       = azurerm_virtual_network_peering.peering_1_to_2.id
  description = "The ID of the peering from VNet 1 to VNet 2."
}

output "peering_1_to_2_name" {
  value       = azurerm_virtual_network_peering.peering_1_to_2.name
  description = "The name of the peering from VNet 1 to VNet 2."
}

output "peering_2_to_1_id" {
  value       = azurerm_virtual_network_peering.peering_2_to_1.id
  description = "The ID of the peering from VNet 2 to VNet 1."
}

output "peering_2_to_1_name" {
  value       = azurerm_virtual_network_peering.peering_2_to_1.name
  description = "The name of the peering from VNet 2 to VNet 1."
}
