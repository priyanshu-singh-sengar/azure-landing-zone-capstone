# 1. Management Group Hierarchy Module
module "management_groups" {
  source = "../../modules/management_groups"

  alz_root_id                = var.alz_root_id
  alz_root_name              = var.alz_root_name
  parent_management_group_id = var.parent_management_group_id
}

# 2. Baseline Policy Assignments across Landing Zones
module "policy_assignment" {
  source = "../../modules/policy_assignment"

  management_group_id   = module.management_groups.landing_zones_id
  allowed_locations     = var.allowed_locations
  enable_deny_public_ip = var.enable_deny_public_ip
  mandatory_tag_name    = var.mandatory_tag_name
}
