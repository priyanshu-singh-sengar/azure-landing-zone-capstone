# modules/management_groups/

## Purpose

Creates the Azure Management Group hierarchy that forms the organisational backbone of the Landing Zone. Management Groups are Azure's resource containers above subscriptions. Policies and RBAC assignments made at a Management Group propagate automatically to all subscriptions within it.

---

## Resources Deployed

The module creates seven management groups in a tree structure:

```
alz-enterprise (ALZ Root)
├── alz-enterprise-platform (Platform)
│   ├── alz-enterprise-platform-management (Management)
│   ├── alz-enterprise-platform-connectivity (Connectivity)
│   └── alz-enterprise-platform-identity (Identity)
├── alz-enterprise-landing-zones (Landing Zones)
│   ├── alz-enterprise-workloads-dev (Dev)
│   ├── alz-enterprise-workloads-test (Test)
│   └── alz-enterprise-workloads-prod (Prod)
├── alz-enterprise-sandboxes (Sandboxes)
└── alz-enterprise-decommissioned (Decommissioned)
```

### ALZ Root

The top-level group under the Tenant Root Group. All organisation-wide policies (e.g., regulatory compliance) are assigned here.

### Platform

Contains subscriptions for shared infrastructure services that workloads depend on but do not own:
- **Management**: Log Analytics, Azure Automation, Update Management
- **Connectivity**: Hub networking, DNS, VPN/ExpressRoute
- **Identity**: Azure AD Domain Services, bastion hosts

### Landing Zones

Contains subscriptions for actual workloads. Policies assigned here enforce workload standards:
- **Dev**: Development environments with relaxed cost controls
- **Test**: Testing environments; may have stricter compliance requirements
- **Prod**: Production environments with the strictest policy controls

### Sandboxes

Isolation for experimentation. Policies here may be more permissive to allow engineers to explore services, but subscriptions are prevented from accessing production data through strict RBAC.

### Decommissioned

A staging area for subscriptions being retired. Moving a subscription here can apply cleanup policies.

---

## Inputs

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `alz_root_id` | No | `alz-enterprise` | Identifier for the root Management Group |
| `alz_root_name` | No | `Enterprise ALZ Root` | Display name for the root group |
| `parent_management_group_id` | No | `null` | Parent group; null places it under Tenant Root |

---

## Outputs

Exposes the IDs of all management groups for use in RBAC and policy assignments:
- `alz_root_id`, `platform_id`, `management_id`, `connectivity_id`, `identity_id`
- `landing_zones_id` (used by policy_assignment module)
- `workloads_dev_id`, `workloads_test_id`, `workloads_prod_id`
- `sandboxes_id`, `decommissioned_id`
