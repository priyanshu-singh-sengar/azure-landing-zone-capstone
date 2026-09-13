# modules/resource_group/

## Purpose

Creates an Azure Resource Group. Resource groups are the fundamental organisational unit in Azure — every resource must belong to exactly one resource group. They serve as the boundary for access control, cost management, and lifecycle management (deleting a resource group deletes all resources within it).

---

## Resources Deployed

### `azurerm_resource_group.rg`

A single resource group with configurable name, location, and tags.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `name` | Yes | — | Resource group name |
| `location` | Yes | — | Azure region |
| `tags` | No | `{}` | Tags to apply |

---

## Outputs

| Output | Value |
|---|---|
| `id` | Resource group resource ID |
| `name` | Resource group name |
| `location` | Resource group location |

---

## Note on Naming

Azure resource naming conventions recommend including the environment, region abbreviation, and a sequence number. For example: `rg-hub-prod-01`, `rg-dev-workloads-01`. The module accepts any name — naming discipline is enforced by the calling layer via variable values.
