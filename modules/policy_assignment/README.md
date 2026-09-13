# modules/policy_assignment/

## Purpose

Assigns Azure Policy definitions to a Management Group scope. Policies enforce governance guardrails — they evaluate resources at creation or update time and either deny the operation, audit a finding, or remediate the non-compliant state. This module uses built-in Microsoft policy definitions referenced by their stable definition IDs.

---

## Resources Deployed

### `azurerm_management_group_policy_assignment.allowed_locations` (conditional)

Assigns the built-in **Allowed locations** policy (`e56962a6-4747-49cd-b67b-bf8b01975c4c`).

Effect: **Deny**. Any resource deployment request that specifies a region not in `var.allowed_locations` is rejected at the ARM API layer before the resource is created.

Parameters: Supplies `listOfAllowedLocations` with the list from `var.allowed_locations`.

Only created if `var.allowed_locations` has at least one entry.

### `azurerm_management_group_policy_assignment.deny_public_ip` (conditional)

Assigns the built-in **Network interfaces should not have public IPs** policy (`83a86a26-fd1f-447c-b59d-e51f44264114`).

Effect: **Deny**. Blocks assigning a public IP address to a VM network interface (NIC). This does not block public IPs on Azure PaaS services (Load Balancers, Application Gateways) — only VM NICs. All VM access must flow through Azure Bastion.

Only created if `var.enable_deny_public_ip = true`.

### `azurerm_management_group_policy_assignment.require_tag_environment` (conditional)

Assigns the built-in **Require a tag on resources** policy (`871b6d14-10aa-478d-b590-94f262ecfa99`).

Effect: **Deny**. Blocks resource creation if the specified tag is absent.

Parameters: Supplies `tagName` with `var.mandatory_tag_name` (default: `Environment`).

Only created if `var.mandatory_tag_name` is non-empty.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `management_group_id` | Yes | — | Scope for policy assignments |
| `allowed_locations` | No | `["eastus","eastus2","centralus"]` | Permitted deployment regions |
| `enable_deny_public_ip` | No | `true` | Enable the public IP deny policy |
| `mandatory_tag_name` | No | `Environment` | Tag name to enforce |

---

## Outputs

| Output | Value |
|---|---|
| `allowed_locations_assignment_id` | Resource ID of the location policy assignment |
| `deny_public_ip_assignment_id` | Resource ID of the public IP deny assignment |
| `require_tag_assignment_id` | Resource ID of the tag requirement assignment |

---

## Why Built-in Policies?

Built-in policy definitions are identified by stable GUIDs that do not change across Azure tenants or subscriptions. Microsoft maintains these definitions. Custom policy definitions would require managing the definition resource (`azurerm_policy_definition`) in addition to the assignment, and would require updates whenever the underlying rule logic needs to change. For standard governance controls like region restriction and tag enforcement, built-in policies are the correct choice.
