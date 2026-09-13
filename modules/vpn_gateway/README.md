# modules/vpn_gateway/

## Purpose

Deploys a Virtual Network Gateway for site-to-site VPN or ExpressRoute connectivity. In this project, it is used for site-to-site VPN (type: `Vpn`, vpn_type: `RouteBased`). The gateway is placed in the Hub VNet's `GatewaySubnet` and can be shared with all spoke VNets through the gateway transit mechanism configured in the VNet peering module.

---

## Resources Deployed

### `azurerm_public_ip.gw_pip`

A zone-redundant Standard SKU public IP for the gateway. Zone redundancy is required when using a zone-redundant gateway SKU (e.g., `VpnGw1AZ`). A zone-redundant gateway distributes its instances across availability zones, maintaining connectivity even if a zone fails.

### `azurerm_virtual_network_gateway.vpn_gateway`

The gateway resource. Key configuration:
- `type = "Vpn"`: Site-to-site VPN (as opposed to `ExpressRoute`).
- `vpn_type = "RouteBased"`: Route-based VPNs are the modern standard and required for all new deployments. Policy-based VPNs are a legacy type with significant limitations.
- `sku = var.sku`: `VpnGw1AZ` in this project — zone-redundant, 650 Mbps aggregate throughput.
- `enable_bgp = false`: Static routing. BGP would be required for dynamic routing with on-premises networks that advertise multiple subnets.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | Gateway name |
| `location` | Yes | — | Azure region |
| `resource_group_name` | Yes | — | Resource group |
| `gateway_subnet_id` | Yes | — | GatewaySubnet resource ID |
| `sku` | No | `VpnGw1AZ` | Gateway SKU |
| `type` | No | `Vpn` | Gateway type (Vpn or ExpressRoute) |
| `vpn_type` | No | `RouteBased` | VPN routing type |
| `enable_bgp` | No | `false` | Enable BGP for dynamic routing |
| `tags` | No | `{}` | Tags |

---

## Outputs

| Output | Value |
|---|---|
| `id` | Gateway resource ID |
| `public_ip` | Gateway public IP (used for VPN device configuration) |

---

## VPN Gateway SKUs

| SKU | Throughput | Zone Redundant | BGP |
|---|---|---|---|
| VpnGw1 | 650 Mbps | No | Yes |
| VpnGw1AZ | 650 Mbps | Yes | Yes |
| VpnGw2AZ | 1 Gbps | Yes | Yes |
| VpnGw3AZ | 1.25 Gbps | Yes | Yes |

The `AZ` suffix indicates zone-redundant deployment. This project uses `VpnGw1AZ` for resilience without exceeding typical bandwidth requirements.

## Note on Provisioning Time

VPN Gateways take 20–45 minutes to provision. This is an Azure platform constraint, not a Terraform issue. Plan CI/CD pipeline timeouts accordingly.
