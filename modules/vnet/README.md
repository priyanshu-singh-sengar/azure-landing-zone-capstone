# modules/vnet/

## Purpose

Creates an Azure Virtual Network with subnets, NSG associations, and route table associations in a single module call. This module is the most widely used in the project — both the Hub and every Spoke call it. By centralising VNet creation, all VNets in the estate follow identical patterns for subnet configuration, association, and tagging.

---

## Resources Deployed

### `azurerm_virtual_network.vnet`

The VNet resource with configurable address space and optional custom DNS servers.

### `azurerm_subnet.subnet`

One subnet per entry in `var.subnets` (a map). Uses `for_each` so each subnet is an independently addressable Terraform resource. Each subnet entry supports:
- `address_prefixes`: The CIDR(s) for the subnet.
- `service_endpoints`: Optional service endpoints (e.g., `Microsoft.Storage`, `Microsoft.Sql`) that grant the subnet direct access to Azure services without going through the public internet.
- `private_endpoint_network_policies_enabled`: Whether network policies (NSG rules, UDRs) apply to private endpoints in this subnet.
- `delegation`: Optional service delegation for subnets hosting specific Azure services (e.g., Azure Container Instances, App Service).

### `azurerm_subnet_network_security_group_association.nsg_assoc`

Associates an NSG with a subnet. Only subnets that appear in `var.subnet_nsg_ids` get an association. This allows some subnets (like GatewaySubnet, which must not have an NSG) to exist without associations.

### `azurerm_subnet_route_table_association.rt_assoc`

Associates a route table with a subnet. Only subnets in `var.subnet_route_table_ids` get an association. This allows `snet-pe` (private endpoints) to have no route table, while `snet-web`, `snet-app`, and `snet-db` all share the forced-tunnelling route table.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | VNet name |
| `location` | Yes | — | Azure region |
| `resource_group_name` | Yes | — | Resource group |
| `address_space` | Yes | — | VNet CIDR(s) |
| `dns_servers` | No | `[]` | Custom DNS server IPs |
| `subnets` | No | `{}` | Map of subnet name to subnet config |
| `subnet_nsg_ids` | No | `{}` | Map of subnet name to NSG ID |
| `subnet_route_table_ids` | No | `{}` | Map of subnet name to Route Table ID |
| `tags` | No | `{}` | Tags |

---

## Outputs

| Output | Value |
|---|---|
| `id` | VNet resource ID |
| `name` | VNet name |
| `subnets` | Map of subnet name to subnet resource ID |

The `subnets` output map allows callers to reference individual subnet IDs without knowing the full resource address. For example: `module.hub_vnet.subnets["AzureFirewallSubnet"]`.

---

## Why This Module Handles Associations

The NSG association and route table association resources could live in the calling layer. However, placing them in the VNet module ensures that callers cannot create a subnet without considering whether it needs an NSG or route table. The module interface makes the relationship explicit — you either pass an NSG ID for a subnet or you do not, and the module handles the rest.
