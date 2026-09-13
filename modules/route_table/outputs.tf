output "id" {
  value       = azurerm_route_table.rt.id
  description = "The ID of the Route Table."
}

output "name" {
  value       = azurerm_route_table.rt.name
  description = "The name of the Route Table."
}

output "subnets" {
  value       = azurerm_route_table.rt.subnets
  description = "The collection of Subnets associated with this Route Table."
}
