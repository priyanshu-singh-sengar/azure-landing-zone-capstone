output "allowed_locations_assignment_id" {
  value       = length(azurerm_management_group_policy_assignment.allowed_locations) > 0 ? azurerm_management_group_policy_assignment.allowed_locations[0].id : null
  description = "The ID of the Allowed Locations policy assignment."
}

output "deny_public_ip_assignment_id" {
  value       = length(azurerm_management_group_policy_assignment.deny_public_ip) > 0 ? azurerm_management_group_policy_assignment.deny_public_ip[0].id : null
  description = "The ID of the Deny Public IP policy assignment."
}

output "mandatory_tag_assignment_id" {
  value       = length(azurerm_management_group_policy_assignment.require_tag_environment) > 0 ? azurerm_management_group_policy_assignment.require_tag_environment[0].id : null
  description = "The ID of the Mandatory Tag policy assignment."
}
