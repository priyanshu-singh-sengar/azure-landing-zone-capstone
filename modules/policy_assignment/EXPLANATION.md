# Policy Assignment Module (`modules/policy_assignment`) — Detailed Explanation

## 1. Overview & Purpose

The `policy_assignment` module applies **built-in Azure Policy definitions** directly to a target **Management Group scope** (`Landing Zones`).

Azure Policies evaluate resources at ARM execution time (`terraform apply`, Azure CLI, Portal). Any operation violating an active `Deny` policy is blocked immediately by ARM before any resource is created.

---

## 2. Policies Assigned

1. **Allowed Locations Policy (`e56962a6-4747-49cd-b67b-bf8b01975c4c`)**:
   - Blocks any resource creation outside approved regions (`eastus`, `eastus2`, `centralus`).
   - Ensures data sovereignty compliance and controls regional egress latency and costs.
2. **Deny Public IPs on Workload NICs (`83a86a26-fd1f-447c-b59d-e51f44264114`)**:
   - **Core Zero-Trust Guardrail**: Forbids attaching public IP addresses to VM or container network interfaces in workload spokes.
   - Forces all inbound traffic through centralized WAFs/Bastion and all outbound traffic through Azure Firewall.
3. **Require Mandatory Resource Tag (`871b6d14-10aa-478d-b590-94f262ecfa99`)**:
   - Requires every resource group or resource to possess the configured tag (e.g., `Environment`).
   - Essential for enterprise FinOps, chargeback, and ownership auditing.

---

## 3. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `management_group_id`: Scope where policies are assigned (e.g., `/providers/Microsoft.Management/managementGroups/alz-enterprise-landing-zones`).
- `allowed_locations`: List of allowed Azure regions.
- `enable_deny_public_ip`: Boolean toggle to activate the Public IP deny rule.
- `mandatory_tag_name`: Name of the required tag key (default: `"Environment"`).

### Outputs (`outputs.tf`)
- `allowed_locations_assignment_id`: Resource ID of the location assignment.
- `deny_public_ip_assignment_id`: Resource ID of the public IP deny assignment.
- `require_tag_assignment_id`: Resource ID of the mandatory tag assignment.
