# modules/nsg/

## Purpose

Creates an Azure Network Security Group (NSG) with a configurable list of security rules. NSGs are stateful packet filters applied at the subnet or NIC level. They control inbound and outbound traffic by evaluating rules in priority order (lowest number = highest priority).

---

## Resources Deployed

### `azurerm_network_security_group.nsg`

The NSG container resource.

### `azurerm_network_security_rule.rules`

One rule resource per entry in `var.security_rules`. Uses `for_each` with the rule name as the key, so adding, removing, or modifying individual rules does not affect others.

Each rule supports:
- `priority`: 100–4096. Rules are evaluated in ascending order. First matching rule wins.
- `direction`: Inbound or Outbound.
- `access`: Allow or Deny.
- `protocol`: TCP, UDP, ICMP, or * (any).
- Source/destination: Can be a CIDR prefix, a service tag (`Internet`, `VirtualNetwork`, `AzureLoadBalancer`, etc.), or an application security group.
- Port ranges: Single value, range (`80-443`), or list (for the `_ranges` variants).

---

## How NSG Rules Are Evaluated

1. For inbound traffic: Azure evaluates NSG rules attached to the subnet, then rules attached to the NIC.
2. For outbound traffic: Rules attached to the NIC are evaluated first, then the subnet NSG.
3. The first matching rule is applied. If no rule matches, the implicit deny-all applies.
4. Priority 65000, 65001, 65500 are reserved Azure default rules (allow VNet-to-VNet, allow load balancer probes, deny all).

---

## Inputs

| Variable | Required | Purpose |
|---|---|---|
| `name` | Yes | NSG name |
| `location` | Yes | Azure region |
| `resource_group_name` | Yes | Resource group |
| `security_rules` | No (empty list default) | List of rule objects |
| `tags` | No | Tags |

Each rule object must include `name`, `priority`, `direction`, `access`, `protocol`. Port and address fields are optional with `lookup()` providing null defaults.

---

## Outputs

| Output | Value |
|---|---|
| `id` | NSG resource ID (passed to VNet module for subnet association) |
| `name` | NSG name |

---

## Why `for_each` Instead of Dynamic Blocks?

Using `for_each` on `azurerm_network_security_rule` creates individual, addressable Terraform resources for each rule. This means:
- Changing one rule only modifies that one resource in state.
- Rules are visible individually in `terraform plan` output.
- Rules can be imported, targeted with `-target`, and tracked independently.

An alternative using `dynamic` blocks inside the NSG resource would create all rules as inline configuration, making granular management harder.
