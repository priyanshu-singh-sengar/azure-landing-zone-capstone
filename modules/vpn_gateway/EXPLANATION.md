# VPN Gateway Module (`modules/vpn_gateway`) — Detailed Explanation

## 1. Overview & Purpose

The `vpn_gateway` module provisions an **Azure Virtual Network Gateway (`azurerm_virtual_network_gateway`)** and its associated Public IP inside `GatewaySubnet`.

In enterprise cloud architecture, the VPN Gateway provides encrypted Site-to-Site (S2S) IPsec tunnels or Point-to-Site (P2S) VPN access connecting corporate offices and datacenters to Azure.

---

## 2. Key Architecture Details

1. **Subnet Constraint**: Must strictly reside within `GatewaySubnet` in the Hub VNet.
2. **Public IP SKU**: Deploys a Standard Static Public IP with optional availability zone resilience (`var.zones`).
3. **Routing & BGP**: Supports route-based VPN and BGP peering (`enable_bgp`) for dynamic route advertisement across enterprise multi-cloud setups.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `name`: Gateway resource name.
- `gateway_subnet_id`: Resource ID of `GatewaySubnet`.
- `sku`: Gateway throughput tier (`"VpnGw1"`, `"VpnGw2"`, etc.).
- `type`: `"Vpn"` or `"ExpressRoute"`.
- `enable_bgp`: Boolean toggle for Border Gateway Protocol dynamic routing.

### Outputs (`outputs.tf`)
- `id`: Resource ID of the Virtual Network Gateway.
- `public_ip`: Public IP address for on-premises IPsec tunnel configuration.
