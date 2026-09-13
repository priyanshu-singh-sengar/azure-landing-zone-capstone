environment         = "test"
location            = "eastus"
resource_group_name = "rg-spoke-test-01"
vnet_name           = "vnet-spoke-test-01"
vnet_address_space  = ["10.2.0.0/16"]

web_subnet_cidr  = "10.2.1.0/24"
app_subnet_cidr  = "10.2.2.0/24"
data_subnet_cidr = "10.2.3.0/24"
pe_subnet_cidr   = "10.2.4.0/24"

hub_vnet_id             = "/subscriptions/23dac4f8-3bad-4f44-acd0-33416f99e104/resourceGroups/rg-hub-prod-01/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-01"
hub_vnet_name           = "vnet-hub-prod-01"
hub_resource_group_name = "rg-hub-prod-01"
hub_firewall_private_ip = "10.0.3.4"

enable_peering      = true
use_remote_gateways = false
enable_test_vm      = false

tags = {
  Environment = "TEST"
  CostCenter  = "QA-Testing-001"
  Owner       = "Workload-QA-Team"
  Project     = "Enterprise-ALZ"
}
