output "alz_root_id" {
  value       = azurerm_management_group.alz_root.id
  description = "The resource ID of the ALZ Root Management Group."
}

output "platform_id" {
  value       = azurerm_management_group.platform.id
  description = "The resource ID of the Platform Management Group."
}

output "management_id" {
  value       = azurerm_management_group.management.id
  description = "The resource ID of the Management Sub-Management Group."
}

output "connectivity_id" {
  value       = azurerm_management_group.connectivity.id
  description = "The resource ID of the Connectivity Sub-Management Group."
}

output "identity_id" {
  value       = azurerm_management_group.identity.id
  description = "The resource ID of the Identity Sub-Management Group."
}

output "landing_zones_id" {
  value       = azurerm_management_group.landing_zones.id
  description = "The resource ID of the Landing Zones Management Group."
}

output "workloads_dev_id" {
  value       = azurerm_management_group.workloads_dev.id
  description = "The resource ID of the Dev Workloads Management Group."
}

output "workloads_test_id" {
  value       = azurerm_management_group.workloads_test.id
  description = "The resource ID of the Test Workloads Management Group."
}

output "workloads_prod_id" {
  value       = azurerm_management_group.workloads_prod.id
  description = "The resource ID of the Prod Workloads Management Group."
}

output "sandboxes_id" {
  value       = azurerm_management_group.sandboxes.id
  description = "The resource ID of the Sandboxes Management Group."
}

output "decommissioned_id" {
  value       = azurerm_management_group.decommissioned.id
  description = "The resource ID of the Decommissioned Management Group."
}
