# VNet Peering Module (`modules/vnet_peering`) — Detailed Explanation

## 1. Overview & Purpose

The `vnet_peering` module provisions a complete **bi-directional Virtual Network Peering pair** connecting two VNets (such as `Hub <-> Dev Spoke`) using Microsoft's private global backbone network.

In Azure, peering is not inherently symmetrical; each VNet must independently initiate a peering connection to the remote VNet. This module encapsulates both directions into a single reusable block.

---

## 2. Gateway Transit & Forwarding Configuration

### 1. Direction 1: Hub to Spoke (`peering_1_to_2`)
- **`allow_virtual_network_access = true`**: Permits VMs in both networks to communicate.
- **`allow_forwarded_traffic = true`**: Allows traffic forwarded by network virtual appliances (Azure Firewall) to transit between VNets.
- **`allow_gateway_transit = true`**: Informs Azure that the remote spoke is permitted to use the Hub's VPN/ExpressRoute gateway.
- **`use_remote_gateways = false`**: Hub has its own gateway; never uses remote gateways.

### 2. Direction 2: Spoke to Hub (`peering_2_to_1`)
- **`allow_gateway_transit = false`**: Spokes do not host gateways for transit.
- **`use_remote_gateways = var.use_remote_gateways`**: When enabled, allows spoke resources to reach on-premises data centers via the Hub's VPN Gateway.
- **`depends_on = [azurerm_virtual_network_peering.peering_1_to_2]`**: Enforces sequential creation to avoid Azure API concurrency conflicts during peering handshake.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `vnet_1_name`, `vnet_1_id`, `vnet_1_rg`: Parameters for VNet 1 (Hub).
- `vnet_2_name`, `vnet_2_id`, `vnet_2_rg`: Parameters for VNet 2 (Spoke).
- `allow_gateway_transit`: Boolean (default `true` on Hub side).
- `use_remote_gateways`: Boolean (default `false`, set to `true` when hybrid transit is active).

### Outputs (`outputs.tf`)
- `peering_1_to_2_id`: Resource ID of the forward peering connection.
- `peering_2_to_1_id`: Resource ID of the reverse peering connection.
