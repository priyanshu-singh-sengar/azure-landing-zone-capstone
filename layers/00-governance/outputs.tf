output "alz_root_management_group_id" {
  value       = module.management_groups.alz_root_id
  description = "Resource ID of the ALZ Root Management Group."
}

output "platform_management_group_id" {
  value       = module.management_groups.platform_id
  description = "Resource ID of the Platform Management Group."
}

output "landing_zones_management_group_id" {
  value       = module.management_groups.landing_zones_id
  description = "Resource ID of the Landing Zones Management Group."
}

output "workloads_dev_management_group_id" {
  value       = module.management_groups.workloads_dev_id
  description = "Resource ID of the Dev Workloads Management Group."
}

output "workloads_test_management_group_id" {
  value       = module.management_groups.workloads_test_id
  description = "Resource ID of the Test Workloads Management Group."
}

output "workloads_prod_management_group_id" {
  value       = module.management_groups.workloads_prod_id
  description = "Resource ID of the Prod Workloads Management Group."
}

output "allowed_locations_policy_id" {
  value       = module.policy_assignment.allowed_locations_assignment_id
  description = "Policy assignment ID for Allowed Locations."
}

output "deny_public_ip_policy_id" {
  value       = module.policy_assignment.deny_public_ip_assignment_id
  description = "Policy assignment ID for Deny Public IP."
}
