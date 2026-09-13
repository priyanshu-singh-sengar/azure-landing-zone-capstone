terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

# 1. Public IP for Azure Firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

# 2. Management Public IP (Required if SKU tier is Basic)
resource "azurerm_public_ip" "fw_mgmt_pip" {
  count               = var.sku_tier == "Basic" ? 1 : 0
  name                = "${var.name}-mgmt-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

# 3. Azure Firewall Policy
resource "azurerm_firewall_policy" "fw_policy" {
  name                = "${var.name}-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku_tier

  dns {
    proxy_enabled = var.enable_dns_proxy
  }

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

# 4. Default Rule Collection Group (Baseline Egress: DNS, NTP, Web Outbound)
resource "azurerm_firewall_policy_rule_collection_group" "default_rules" {
  name               = "default-egress-rules"
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  priority           = 1000

  network_rule_collection {
    name     = "core-infra-services"
    priority = 1100
    action   = "Allow"

    rule {
      name                  = "allow-dns-outbound"
      protocols             = ["UDP", "TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_ports     = ["53"]
      destination_addresses = ["*"]
    }

    rule {
      name                  = "allow-ntp-outbound"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_ports     = ["123"]
      destination_addresses = ["*"]
    }
  }

  application_rule_collection {
    name     = "standard-web-egress"
    priority = 1200
    action   = "Allow"

    rule {
      name             = "allow-safe-outbound-web"
      source_addresses = ["10.0.0.0/8"]

      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }

      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com",
        "*.windowsupdate.com",
        "*.ubuntu.com",
        "github.com",
        "*.github.com"
      ]
    }
  }
}

# 5. Azure Firewall Instance
resource "azurerm_firewall" "fw" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.sku_tier
  firewall_policy_id  = azurerm_firewall_policy.fw_policy.id

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }

  dynamic "management_ip_configuration" {
    for_each = var.sku_tier == "Basic" ? [1] : []
    content {
      name                 = "fw-mgmt-ipconfig"
      subnet_id            = var.firewall_management_subnet_id
      public_ip_address_id = azurerm_public_ip.fw_mgmt_pip[0].id
    }
  }

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}
