# modules/vnet_peering/

## Purpose

Creates a bi-directional VNet peering pair. VNet peering is a networking connection between two Azure VNets that routes traffic between them using the Microsoft backbone network (not the public internet). Peering is not transitive — if VNet A is peered with Hub, and VNet B is peered with Hub, VNet A cannot reach VNet B directly without routing through a Network Virtual Appliance (the Azure Firewall) in the Hub.

---

## Resources Deployed

### `azurerm_virtual_network_peering.peering_1_to_2`

The first direction of the peering — from VNet 1 (Hub) to VNet 2 (Spoke).

Key settings:
- `allow_gateway_transit = var.allow_gateway_transit`: Set to `true` on the Hub side. This tells Azure that the Hub's VPN Gateway can be used by the peered VNet (the Spoke). This enables gateway transit — the Spoke benefits from the Hub's on-premises VPN connectivity without needing its own gateway.
- `use_remote_gateways = false`: The Hub does not need to use a remote gateway — it has its own.
- `allow_forwarded_traffic = var.allow_forwarded_traffic`: Enables traffic that did not originate in VNet 1 to be forwarded through the peering. This is required for the Hub-to-internet flow on behalf of spoke VMs.

### `azurerm_virtual_network_peering.peering_2_to_1`

The second direction — from VNet 2 (Spoke) to VNet 1 (Hub).

Key settings:
- `allow_gateway_transit = false`: The Spoke does not own a gateway; it cannot offer gateway transit to others.
- `use_remote_gateways = var.use_remote_gateways`: Set to `true` on the Spoke side. Tells the Spoke to use the Hub's VPN Gateway for routing to on-premises networks.
- `depends_on = [azurerm_virtual_network_peering.peering_1_to_2]`: The spoke-to-hub peering can only be created after the hub-to-spoke peering exists. Azure requires the first direction to be in a `Connected` state before the second can be configured with `use_remote_gateways = true`.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `vnet_1_name` | Yes | — | Hub VNet name |
| `vnet_1_id` | Yes | — | Hub VNet resource ID |
| `vnet_1_rg` | Yes | — | Hub VNet resource group |
| `vnet_2_name` | Yes | — | Spoke VNet name |
| `vnet_2_id` | Yes | — | Spoke VNet resource ID |
| `vnet_2_rg` | Yes | — | Spoke VNet resource group |
| `allow_virtual_network_access` | No | `true` | Permit traffic between peered VNets |
| `allow_forwarded_traffic` | No | `true` | Permit forwarded (not originating) traffic |
| `allow_gateway_transit` | No | `true` | Hub shares its gateway with the spoke |
| `use_remote_gateways` | No | `false` | Spoke uses hub gateway (set to true in spoke calls) |
| `peering_name_1_to_2` | No | `null` | Custom name for hub-to-spoke peering |
| `peering_name_2_to_1` | No | `null` | Custom name for spoke-to-hub peering |

---

## Outputs

| Output | Value |
|---|---|
| `peering_1_to_2_id` | Hub-to-spoke peering resource ID |
| `peering_2_to_1_id` | Spoke-to-hub peering resource ID |

---

## Why `depends_on` Is Needed

Terraform derives resource ordering from references. Neither peering resource references the other — they are independent resources that both reference the two VNet IDs. Without `depends_on`, Terraform might try to create both peerings simultaneously. Azure's API rejects creating a peering with `use_remote_gateways = true` if the other direction does not yet exist. The explicit `depends_on` enforces sequencing.
