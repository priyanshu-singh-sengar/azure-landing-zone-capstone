output "id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The ID of the Virtual Network."
}

output "name" {
  value       = azurerm_virtual_network.vnet.name
  description = "The name of the Virtual Network."
}

output "address_space" {
  value       = azurerm_virtual_network.vnet.address_space
  description = "The address space of the Virtual Network."
}

output "subnets" {
  value       = { for k, v in azurerm_subnet.subnet : k => v.id }
  description = "Map of subnet names to their respective Subnet IDs."
}

output "subnet_objects" {
  value       = azurerm_subnet.subnet
  description = "Map of subnet names to full subnet resource objects."
}
