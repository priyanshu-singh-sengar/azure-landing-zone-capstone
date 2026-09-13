output "resource_group_name" {
  value       = module.hub_rg.name
  description = "Name of the Hub Resource Group."
}

output "vnet_id" {
  value       = module.hub_vnet.id
  description = "ID of the Hub Virtual Network."
}

output "vnet_name" {
  value       = module.hub_vnet.name
  description = "Name of the Hub Virtual Network."
}

output "vnet_address_space" {
  value       = module.hub_vnet.address_space
  description = "Address space of the Hub Virtual Network."
}

output "subnets" {
  value       = module.hub_vnet.subnets
  description = "Map of Hub subnet names to subnet IDs."
}

output "firewall_id" {
  value       = module.azure_firewall.id
  description = "Resource ID of the Azure Firewall."
}

output "firewall_private_ip" {
  value       = module.azure_firewall.private_ip_address
  description = "Private IP address of the Azure Firewall (target for Spoke UDR default routes)."
}

output "firewall_public_ip" {
  value       = module.azure_firewall.public_ip_address
  description = "Public IP address of the Azure Firewall."
}

output "bastion_id" {
  value       = module.bastion.id
  description = "Resource ID of the Azure Bastion Host."
}

output "vpn_gateway_id" {
  value       = var.enable_vpn_gateway ? module.vpn_gateway[0].id : null
  description = "Resource ID of the Virtual Network Gateway (if enabled)."
}
