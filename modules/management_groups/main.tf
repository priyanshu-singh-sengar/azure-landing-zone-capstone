# 1. Top-level ALZ Root Management Group under Tenant Root
resource "azurerm_management_group" "alz_root" {
  name                       = var.alz_root_id
  display_name               = var.alz_root_name
  parent_management_group_id = var.parent_management_group_id
}

# 2. Platform Management Group
resource "azurerm_management_group" "platform" {
  name                       = "${var.alz_root_id}-platform"
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.alz_root.id
}

resource "azurerm_management_group" "management" {
  name                       = "${var.alz_root_id}-platform-management"
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "connectivity" {
  name                       = "${var.alz_root_id}-platform-connectivity"
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "identity" {
  name                       = "${var.alz_root_id}-platform-identity"
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

# 3. Landing Zones (Workloads) Management Group
resource "azurerm_management_group" "landing_zones" {
  name                       = "${var.alz_root_id}-landing-zones"
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.alz_root.id
}

resource "azurerm_management_group" "workloads_dev" {
  name                       = "${var.alz_root_id}-workloads-dev"
  display_name               = "Dev"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "workloads_test" {
  name                       = "${var.alz_root_id}-workloads-test"
  display_name               = "Test"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "workloads_prod" {
  name                       = "${var.alz_root_id}-workloads-prod"
  display_name               = "Prod"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

# 4. Sandboxes Management Group
resource "azurerm_management_group" "sandboxes" {
  name                       = "${var.alz_root_id}-sandboxes"
  display_name               = "Sandboxes"
  parent_management_group_id = azurerm_management_group.alz_root.id
}

# 5. Decommissioned Management Group
resource "azurerm_management_group" "decommissioned" {
  name                       = "${var.alz_root_id}-decommissioned"
  display_name               = "Decommissioned"
  parent_management_group_id = azurerm_management_group.alz_root.id
}
