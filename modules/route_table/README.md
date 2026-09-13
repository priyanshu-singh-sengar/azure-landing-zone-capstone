# modules/route_table/

## Purpose

Creates an Azure Route Table and its associated routes. Route tables override Azure's default system routes, enabling custom traffic routing decisions. In this project, route tables are used to implement forced tunnelling — directing all internet-bound traffic from spoke subnets to the Azure Firewall in the hub.

---

## Resources Deployed

### `azurerm_route_table.rt`

The route table container. The `disable_bgp_route_propagation` variable controls whether routes advertised from a VPN Gateway via BGP are added to this route table automatically. In most hub-and-spoke designs, this is set to `true` (disabled) for spoke subnets to prevent on-premises routes from being automatically propagated and potentially overriding the forced-tunnelling UDR.

### `azurerm_route.routes`

One route resource per entry in `var.routes`. Uses `for_each` with the route name as the key. Key route properties:

- `address_prefix`: The destination CIDR this route applies to (e.g., `0.0.0.0/0` for all traffic).
- `next_hop_type`: One of:
  - `VirtualAppliance`: Route to a specific IP (used with Azure Firewall)
  - `VnetLocal`: Default VNet routing
  - `Internet`: Direct internet (bypasses firewall — not used here)
  - `VirtualNetworkGateway`: Send to VPN/ExpressRoute gateway
  - `None`: Drop the traffic (black hole)
- `next_hop_in_ip_address`: Required when `next_hop_type = VirtualAppliance`. The IP of the Azure Firewall.

**Note:** The route table must be associated with a subnet to take effect. The association is handled by the `vnet` module via `azurerm_subnet_route_table_association`.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | Route table name |
| `location` | Yes | — | Azure region |
| `resource_group_name` | Yes | — | Resource group |
| `routes` | No | `[]` | List of route objects |
| `disable_bgp_route_propagation` | No | `false` | Prevent BGP route propagation |
| `tags` | No | `{}` | Tags |

---

## Outputs

| Output | Value |
|---|---|
| `id` | Route table resource ID (passed to VNet module for subnet association) |
| `name` | Route table name |
