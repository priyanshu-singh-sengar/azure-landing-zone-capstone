# Virtual Network Module (`modules/vnet`) — Detailed Explanation

## 1. Overview & Purpose

The `vnet` module provisions an **Azure Virtual Network (`azurerm_virtual_network`)**, child subnets (`azurerm_subnet`), and handles associations for Network Security Groups and Route Tables.

It is instantiated across both the Hub (`10.0.0.0/16`) and all Spoke environments (`10.1.0.0/16`, `10.2.0.0/16`, `10.3.0.0/16`).

---

## 2. Key Architecture Capabilities

1. **Map-Driven Subnet Allocation**: Subnets are defined as a flexible map of objects, supporting custom address prefixes, service endpoints, private endpoint policies, and subnet delegations.
2. **Explicit Association Decoupling**: Rather than declaring NSG or Route Table attachments inside the subnet resource (which Azure deprecates), dedicated association resources are used:
   - `azurerm_subnet_network_security_group_association`
   - `azurerm_subnet_route_table_association`
   This prevents circular dependencies between VNet, NSG, and Route Table provisioning.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `name`: Name of the VNet.
- `address_space`: List of IP address blocks (e.g., `["10.0.0.0/16"]`).
- `subnets`: Map of subnets to create.
- `subnet_nsg_ids`: Map linking subnet names to NSG resource IDs.
- `subnet_route_table_ids`: Map linking subnet names to Route Table resource IDs.

### Outputs (`outputs.tf`)
- `id`: Resource ID of the Virtual Network.
- `name`: Name of the Virtual Network.
- `subnets`: Map of created subnet names to their resource IDs (e.g., `module.hub_vnet.subnets["AzureFirewallSubnet"]`).
