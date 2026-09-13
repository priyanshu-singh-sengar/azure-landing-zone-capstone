location            = "eastus"
resource_group_name = "rg-hub-prod-01"
vnet_name           = "vnet-hub-prod-01"
vnet_address_space  = ["10.0.0.0/16"]

gateway_subnet_cidr       = "10.0.1.0/24"
bastion_subnet_cidr       = "10.0.2.0/26"
firewall_subnet_cidr      = "10.0.3.0/26"
firewall_mgmt_subnet_cidr = "10.0.3.128/26"
shared_svc_subnet_cidr    = "10.0.4.0/24"

firewall_name     = "afw-hub-prod-01"
firewall_sku_tier = "Standard"

bastion_name = "bas-hub-prod-01"
bastion_sku  = "Standard"

enable_vpn_gateway = true
vpn_gateway_name   = "vpngw-hub-prod-01"
vpn_gateway_sku    = "VpnGw1AZ"

tags = {
  Environment = "Hub-Platform"
  CostCenter  = "Core-Network-001"
  Owner       = "Cloud-Platform-Team"
  Project     = "Enterprise-ALZ"
}
