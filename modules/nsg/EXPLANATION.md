# Network Security Group Module (`modules/nsg`) — Detailed Explanation

## 1. Overview & Purpose

The `nsg` module provisions an **Azure Network Security Group (NSG)** along with a dynamic list of custom security rules (`azurerm_network_security_rule`).

In network security, NSGs act as stateful Layer 4 packet filters applied at the subnet boundary. They evaluate incoming and outgoing packets against priority-ordered rules to implement microsegmentation.

---

## 2. Key Design Decisions

### Dynamic Rule Expansion via `for_each`
Instead of using inline `security_rule` blocks inside `azurerm_network_security_group`, the module creates discrete `azurerm_network_security_rule` resources keyed by rule name:

```hcl
resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.security_rules : rule.name => rule }
  ...
}
```

#### Why This Matters:
1. **Zero Index Shuffling:** In list-based inline rules, inserting a new rule at priority 150 shifts all subsequent indices, causing Terraform to destroy and recreate rules. Keying by name ensures Terraform updates only the specific rule changed.
2. **Support for Port and CIDR Plurality:** The module uses `lookup()` to safely handle either singular (`source_port_range`) or plural (`source_port_ranges`) fields without schema errors.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `name`: Name of the NSG (e.g., `nsg-prod-web`).
- `location`, `resource_group_name`, `tags`.
- `security_rules`: A list of maps containing:
  - `name`, `priority` (100–4096), `direction` (`Inbound`/`Outbound`), `access` (`Allow`/`Deny`), `protocol` (`Tcp`/`Udp`/`*`).
  - Singular or plural source and destination ports and address prefixes.

### Outputs (`outputs.tf`)
- `id`: Resource ID of the NSG, used by the `vnet` module to associate the NSG to target subnets.
- `name`: Name of the NSG.
