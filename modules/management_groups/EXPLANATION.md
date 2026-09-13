# Management Groups Module (`modules/management_groups`) — Detailed Explanation

## 1. Overview & Purpose

The `management_groups` module creates the canonical **Cloud Adoption Framework (CAF) Management Group hierarchy**.

In Microsoft Azure, Management Groups are containers situated above subscriptions. Applying RBAC permissions and Azure Policy at a parent Management Group automatically cascades down through inheritance to every child subscription, eliminating manual configuration drift.

---

## 2. Hierarchy Tree

```text
Tenant Root Group
 └── ALZ Root (alz-enterprise)
      ├── Platform
      │    ├── Management    --> Central Log Analytics, automation accounts
      │    ├── Connectivity  --> Hub VNet, Azure Firewall, Bastion, Gateways
      │    └── Identity      --> Active Directory, Key Vaults, Domain Controllers
      ├── Landing Zones      --> Workload subscriptions with guardrails
      │    ├── Dev           --> Non-production development subscriptions
      │    ├── Test          --> Staging/QA subscriptions
      │    └── Prod          --> High-availability production workloads
      ├── Sandboxes          --> Isolated developer experimentation
      └── Decommissioned     --> Offboarded subscriptions pending deletion
```

---

## 3. Code Walkthrough (`main.tf`)

- **Root Container (`azurerm_management_group.alz_root`)**: Parented directly to `Tenant Root Group` (or a custom parent ID).
- **Platform Branch (`azurerm_management_group.platform`)**: Houses platform operations separated into `management`, `connectivity`, and `identity`.
- **Landing Zones Branch (`azurerm_management_group.landing_zones`)**: Houses application environments divided into `workloads_dev`, `workloads_test`, and `workloads_prod`.
- **Sandboxes & Decommissioned**: Isolates untrusted R&D experiments and cleanly archives decommissioned subscriptions before permanent deletion.

---

## 4. Inputs & Outputs

### Key Inputs (`variables.tf`)
- `alz_root_id`: Alphanumeric slug identifier (e.g., `"alz-enterprise"`).
- `alz_root_name`: Display name shown in Azure Portal (e.g., `"Enterprise ALZ Root"`).
- `parent_management_group_id`: Optional parent ID; defaults to Tenant Root Group.

### Outputs (`outputs.tf`)
- Exposes IDs for all 10 management groups (`alz_root_id`, `platform_id`, `connectivity_id`, `landing_zones_id`, `workloads_dev_id`, `workloads_prod_id`, etc.) to allow policy assignments and subscription placements.
