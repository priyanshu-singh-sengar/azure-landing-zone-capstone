# modules/bastion/

## Purpose

Deploys an Azure Bastion Host with its required Public IP. Azure Bastion provides browser-based and native-client SSH/RDP access to VMs without requiring a public IP address on the VMs themselves. All traffic is encrypted over HTTPS port 443, eliminating the attack surface of an exposed SSH or RDP port.

---

## Resources Deployed

### `azurerm_public_ip.bastion_pip`

A Standard SKU static public IP. Bastion requires Standard SKU. This IP is the only public ingress point — users connect to it from a browser or native client. Despite having a public IP, the Bastion host accepts only HTTPS (port 443), enforced by the mandatory NSG rules on the AzureBastionSubnet.

### `azurerm_bastion_host.bastion`

The Bastion host resource. Key settings:
- `sku = var.sku`: Standard SKU in this deployment. Standard unlocks native client support (SSH/RDP from a terminal instead of browser), file copy, and tunnelling.
- `tunneling_enabled = true`: Enables native client tunnelling. Only available on Standard SKU, so the module conditionally sets this to `null` for Basic SKU.
- `file_copy_enabled`: Controlled by variable, available on Standard SKU only.
- `ip_configuration.subnet_id`: Must reference the `AzureBastionSubnet` specifically.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | Bastion host name |
| `location` | Yes | — | Azure region |
| `resource_group_name` | Yes | — | Resource group |
| `sku` | No | `Standard` | Bastion SKU (Basic or Standard) |
| `bastion_subnet_id` | Yes | — | AzureBastionSubnet resource ID |
| `tunneling_enabled` | No | `true` | Enable native client tunnelling (Standard only) |
| `file_copy_enabled` | No | `false` | Enable file copy feature (Standard only) |
| `tags` | No | `{}` | Tags |

---

## Outputs

| Output | Value |
|---|---|
| `id` | Bastion Host resource ID |
| `public_ip` | Bastion public IP address |

---

## Why Standard SKU?

The Basic SKU provides browser-only SSH/RDP through the Azure portal. The Standard SKU adds native client support (so you can use your local terminal app instead of the browser) and tunnelling (required for some tools that need a direct TCP connection). For a production enterprise environment, Standard is the appropriate choice.
