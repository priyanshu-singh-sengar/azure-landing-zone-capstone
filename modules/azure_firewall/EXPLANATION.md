# Azure Firewall Module (`modules/azure_firewall`) — Detailed Explanation

## 1. Overview & Purpose

The `azure_firewall` module deploys a centrally managed **Azure Firewall (VNet-integrated)** paired with an **Azure Firewall Policy** and a baseline **Rule Collection Group**.

In the Hub-and-Spoke Landing Zone, Azure Firewall provides stateful Layer 3–Layer 7 inspection, centralized egress filtering, and Threat Intelligence.

---

## 2. Resources Created

1. **`azurerm_public_ip.fw_pip`**: Static Standard Public IP for data plane egress (SNAT).
2. **`azurerm_public_ip.fw_mgmt_pip`**: Dedicated management Public IP created conditionally (`var.sku_tier == "Basic"`).
3. **`azurerm_firewall_policy.fw_policy`**: Modern centralized policy object detached from legacy inline firewall rules, with DNS Proxy capability enabled.
4. **`azurerm_firewall_policy_rule_collection_group.default_rules`**: Baseline rule collections:
   - **Network Rules (Priority 1100)**: Outbound DNS (UDP/TCP 53) and NTP (UDP 123) from private `10.0.0.0/8` ranges.
   - **Application Rules (Priority 1200)**: HTTP (`80`) and HTTPS (`443`) egress restricted to approved FQDNs (`*.microsoft.com`, `*.azure.com`, `*.ubuntu.com`, `*.github.com`).
5. **`azurerm_firewall.fw`**: The firewall instance deployed into `AzureFirewallSubnet`.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `name`: Base name for the firewall and child resources.
- `sku_tier`: `"Basic"`, `"Standard"`, or `"Premium"`.
- `firewall_subnet_id`: Resource ID of the `AzureFirewallSubnet` in Hub VNet.
- `firewall_management_subnet_id`: Required if `sku_tier` is `"Basic"`.
- `enable_dns_proxy`: Boolean to route DNS queries through the firewall.

### Outputs (`outputs.tf`)
- `id`: Resource ID of the firewall instance.
- `private_ip`: The internal IP address (typically `10.0.3.4`), used as the next hop in Spoke Route Tables.
- `public_ip`: Public IP address used for outbound internet SNAT.
- `policy_id`: ID of the attached firewall policy for attaching additional rules.
