terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

# 1. Allowed Locations Policy Assignment
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  count                = length(var.allowed_locations) > 0 ? 1 : 0
  name                 = "deny-unapproved-locs"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
  display_name         = "Allowed locations"
  description          = "Restricts resource deployments strictly to approved geographic regions."

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

# 2. Deny Public IPs on Workload Network Interfaces
resource "azurerm_management_group_policy_assignment" "deny_public_ip" {
  count                = var.enable_deny_public_ip ? 1 : 0
  name                 = "deny-public-ip-nic"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/83a86a26-fd1f-447c-b59d-e51f44264114"
  display_name         = "Network interfaces should not have public IPs"
  description          = "Enforces zero direct public ingress on workload network interfaces."
}

# 3. Require Mandatory Tag on Resources
resource "azurerm_management_group_policy_assignment" "require_tag_environment" {
  count                = var.mandatory_tag_name != "" ? 1 : 0
  name                 = "req-tag-${substr(lower(var.mandatory_tag_name), 0, 16)}"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  display_name         = "Require tag '${var.mandatory_tag_name}' on resources"
  description          = "Enforces mandatory tagging compliance across landing zone resources."

  parameters = jsonencode({
    tagName = {
      value = var.mandatory_tag_name
    }
  })
}
