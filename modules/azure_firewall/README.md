# modules/azure_firewall/

## Purpose

Deploys a complete Azure Firewall with a Firewall Policy and a default set of egress rules. This module encapsulates every resource required for a functional firewall — you do not need to create any supplementary resources separately.

---

## Resources Deployed

### `azurerm_public_ip.fw_pip`

A Standard SKU static public IP for the firewall data plane. Standard SKU is required for Azure Firewall (Basic SKU PIPs are not supported). The IP is static so that its address is stable and can be referenced in on-premises firewall allowlists.

### `azurerm_public_ip.fw_mgmt_pip` (conditional)

Created only when `sku_tier == "Basic"`. The Basic Firewall SKU requires a separate management public IP for the out-of-band management channel. Standard and Premium SKUs do not require this IP.

### `azurerm_firewall_policy.fw_policy`

A Firewall Policy resource that acts as a centralised container for rule collection groups. Using a Firewall Policy (rather than classic firewall rules) is required for Standard and Premium SKUs and enables features like DNS proxy, IDPS, and TLS inspection (Premium). The DNS proxy is enabled here, which causes the firewall to act as a DNS forwarder for all VMs that use the firewall IP as their DNS server.

### `azurerm_firewall_policy_rule_collection_group.default_rules`

The baseline rule collection group at priority 1000:

**Network rule collection `core-infra-services` (priority 1100, Allow):**
- DNS (UDP/TCP port 53) from `10.0.0.0/8` to any destination: Allows all internal VMs to resolve DNS names.
- NTP (UDP port 123) from `10.0.0.0/8` to any destination: Allows time synchronisation, critical for certificate validation and logging.

**Application rule collection `standard-web-egress` (priority 1200, Allow):**
- HTTP (80) and HTTPS (443) from `10.0.0.0/8` to:
  - `*.microsoft.com`, `*.azure.com`: Azure management, telemetry
  - `*.windowsupdate.com`: Windows patching
  - `*.ubuntu.com`: Ubuntu patching
  - `github.com`, `*.github.com`: Source code, package downloads

All other traffic is denied by Azure Firewall's implicit default deny.

### `azurerm_firewall.fw`

The Azure Firewall instance. Key settings:
- `sku_name = "AZFW_VNet"`: Deploys in a VNet (as opposed to a Virtual Hub for Azure Virtual WAN).
- `sku_tier = var.sku_tier`: Standard in this deployment.
- `firewall_policy_id`: Associates the Firewall Policy created above.
- `ip_configuration`: Attaches the data plane public IP and the firewall subnet.
- `management_ip_configuration`: Added dynamically only for Basic SKU.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | Firewall resource name |
| `location` | Yes | — | Azure region |
| `resource_group_name` | Yes | — | Resource group |
| `sku_tier` | No | `Standard` | Firewall tier |
| `firewall_subnet_id` | Yes | — | AzureFirewallSubnet resource ID |
| `firewall_management_subnet_id` | No | `null` | Management subnet ID (Basic SKU only) |
| `enable_dns_proxy` | No | `true` | Enable DNS proxy on the Firewall Policy |
| `tags` | No | `{}` | Tags to apply to all resources |

---

## Outputs

| Output | Value |
|---|---|
| `id` | Azure Firewall resource ID |
| `private_ip` | Firewall private IP address (used as UDR next hop in spokes) |
| `public_ip` | Firewall data plane public IP address |
