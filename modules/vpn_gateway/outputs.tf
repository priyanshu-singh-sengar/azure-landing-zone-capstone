output "id" {
  value       = azurerm_virtual_network_gateway.gateway.id
  description = "The ID of the Virtual Network Gateway."
}

output "name" {
  value       = azurerm_virtual_network_gateway.gateway.name
  description = "The name of the Virtual Network Gateway."
}

output "public_ip_address" {
  value       = azurerm_public_ip.gw_pip.ip_address
  description = "The public IP address of the Virtual Network Gateway."
}
