# Modules Directory — Architecture & Design System Explanation

## 1. Overview & Core Philosophy

The `modules/` directory contains all **reusable, self-contained Terraform child modules**. 

In cloud engineering, modules are the fundamental building blocks of Infrastructure as Code. Instead of repeatedly declaring raw `azurerm_virtual_network`, `azurerm_network_security_group`, or `azurerm_firewall` resources across dev, test, and prod environments, each pattern is encapsulated within a hardened module with opinionated security defaults.

---

## 2. The Child Module Contract

Every module in this directory strictly adheres to the standard Terraform module contract:

```text
modules/<module_name>/
├── main.tf        --> Pure resource declarations and local transformations
├── variables.tf   --> Explicit input contracts (types, descriptions, defaults)
├── outputs.tf     --> Curated output interfaces (IDs, names, IPs)
└── EXPLANATION.md --> File-by-file walkthrough and usage manual
```

### Key Architectural Rules

1. **No Backend Blocks:** Child modules never declare a `terraform { backend "..." {} }` block. State is always owned and locked by the root caller layer (`layers/01-connectivity-hub`, etc.).
2. **Explicit Dependency Injection:** Modules never perform hidden lookups using `data` blocks to grab outside state. If a module requires an external resource (e.g., a subnet ID or public IP), that value must be passed explicitly via `variables.tf`. This keeps modules completely testable in isolation.
3. **Opinionated Security Baseline:** Security policies are encoded directly into the modules. For example:
   - Storage accounts default to `TLS 1.2` with versioning enabled.
   - Firewalls default to managed DNS proxying.
   - Resource groups enforce standard tags.
4. **Mandatory Tag Propagation:** Every module merges the caller's `var.tags` with a global tag: `IaC_Managed = "Terraform"`. Any resource in the Azure portal lacking this tag was deployed out-of-band and constitutes drift.

---

## 3. Directory Catalog

| Module | Core Azure Resources Managed | Why It Exists |
|---|---|---|
| **[azure_firewall](file:///d:/az400/landingZone/modules/azure_firewall/EXPLANATION.md)** | `azurerm_public_ip`, `azurerm_firewall_policy`, `azurerm_firewall_policy_rule_collection_group`, `azurerm_firewall` | Centralizes perimeter security, FQDN filtering, and threat intelligence. |
| **[bastion](file:///d:/az400/landingZone/modules/bastion/EXPLANATION.md)** | `azurerm_public_ip`, `azurerm_bastion_host` | Enables zero-public-IP VM management via browser/CLI TLS tunnels. |
| **[management_groups](file:///d:/az400/landingZone/modules/management_groups/EXPLANATION.md)** | `azurerm_management_group` | Builds the 7-group Cloud Adoption Framework governance tree. |
| **[nsg](file:///d:/az400/landingZone/modules/nsg/EXPLANATION.md)** | `azurerm_network_security_group`, `azurerm_network_security_rule` | Reusable microsegmentation engine with dynamic rule expansion. |
| **[policy_assignment](file:///d:/az400/landingZone/modules/policy_assignment/EXPLANATION.md)** | `azurerm_management_group_policy_assignment` | Enforces corporate guardrails (allowed regions, deny public IPs, tags). |
| **[resource_group](file:///d:/az400/landingZone/modules/resource_group/EXPLANATION.md)** | `azurerm_resource_group` | Standardized lifecycle container and tag propagation. |
| **[route_table](file:///d:/az400/landingZone/modules/route_table/EXPLANATION.md)** | `azurerm_route_table`, `azurerm_route` | Overrides system routes to implement forced tunneling (`0.0.0.0/0 -> 10.0.3.4`). |
| **[vnet](file:///d:/az400/landingZone/modules/vnet/EXPLANATION.md)** | `azurerm_virtual_network`, `azurerm_subnet`, associations | Manages IP address spaces, subnets, and subnet-to-NSG/UDR bindings. |
| **[vnet_peering](file:///d:/az400/landingZone/modules/vnet_peering/EXPLANATION.md)** | `azurerm_virtual_network_peering` (x2) | Creates symmetric bi-directional peering pairs with gateway transit. |
| **[vpn_gateway](file:///d:/az400/landingZone/modules/vpn_gateway/EXPLANATION.md)** | `azurerm_public_ip` (x2), `azurerm_virtual_network_gateway` | High-availability active-active Site-to-Site IPsec VPN termination. |
