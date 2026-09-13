output "resource_group_name" {
  value       = module.spoke_rg.name
  description = "Name of the Spoke Resource Group."
}

output "vnet_id" {
  value       = module.spoke_vnet.id
  description = "ID of the Spoke Virtual Network."
}

output "vnet_name" {
  value       = module.spoke_vnet.name
  description = "Name of the Spoke Virtual Network."
}

output "subnets" {
  value       = module.spoke_vnet.subnets
  description = "Map of Spoke subnet names to Subnet IDs."
}

output "route_table_id" {
  value       = module.spoke_route_table.id
  description = "ID of the Spoke Route Table."
}

output "web_nsg_id" {
  value       = module.web_nsg.id
  description = "ID of the Web Tier NSG."
}

output "app_nsg_id" {
  value       = module.app_nsg.id
  description = "ID of the App Tier NSG."
}

output "db_nsg_id" {
  value       = module.db_nsg.id
  description = "ID of the DB Tier NSG."
}

output "peering_hub_to_spoke_id" {
  value       = var.enable_peering ? module.peering[0].peering_1_to_2_id : null
  description = "ID of the peering from Hub to Spoke."
}

output "peering_spoke_to_hub_id" {
  value       = var.enable_peering ? module.peering[0].peering_2_to_1_id : null
  description = "ID of the peering from Spoke to Hub."
}

output "test_vm_id" {
  value       = var.enable_test_vm ? azurerm_linux_virtual_machine.test_vm[0].id : null
  description = "ID of the validation test VM (if deployed)."
}

output "test_vm_private_ip" {
  value       = var.enable_test_vm ? azurerm_network_interface.test_nic[0].private_ip_address : null
  description = "Private IP address of the validation VM."
}
