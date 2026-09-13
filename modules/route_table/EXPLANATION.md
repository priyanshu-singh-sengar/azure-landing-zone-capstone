# Route Table Module (`modules/route_table`) — Detailed Explanation

## 1. Overview & Purpose

The `route_table` module provisions an **Azure Route Table** (`azurerm_route_table`) and dynamic User-Defined Routes (`azurerm_route`).

In Azure networking, system routes automatically route internet-bound traffic directly out to the public internet. Attaching a Route Table with custom UDRs overrides this default behavior to implement **forced tunneling**.

---

## 2. Key Architecture Pattern: Forced Tunneling

In this Landing Zone, the Spoke Route Table defines a catch-all route:
- **`address_prefix`**: `0.0.0.0/0` (all IPv4 traffic)
- **`next_hop_type`**: `VirtualAppliance`
- **`next_hop_in_ip_address`**: `10.0.3.4` (Azure Firewall Private IP)

This forces all VM outbound traffic across VNet peering into the Azure Firewall for inspection, logging, and filtering.

---

## 3. Dynamic Route Generation via `for_each`

Individual routes are managed as discrete `azurerm_route` resources keyed by route name:
```hcl
resource "azurerm_route" "routes" {
  for_each = { for r in var.routes : r.name => r }
  ...
}
```
This isolates route modifications, preventing Terraform from recreating unaffected routes during updates.

---

## 4. Inputs & Outputs

### Inputs (`variables.tf`)
- `name`: Route table name (e.g., `rt-dev-spoke-01`).
- `disable_bgp_route_propagation`: Disables learning on-premises routes advertised via BGP (defaults to `false`).
- `routes`: List of route definitions (`name`, `address_prefix`, `next_hop_type`, `next_hop_in_ip_address`).

### Outputs (`outputs.tf`)
- `id`: Resource ID of the Route Table, associated to subnets by the `vnet` module.
- `name`: Name of the Route Table.
