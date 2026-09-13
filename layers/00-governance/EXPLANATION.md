# Governance Layer (`layers/00-governance`) — Detailed Explanation

## 1. Overview & Purpose

The `layers/00-governance` layer implements the **organizational foundation and compliance guardrails** of the Azure Landing Zone. It sets up:
1. The Cloud Adoption Framework (CAF) Management Group hierarchy.
2. Baseline Azure Policy assignments to prevent policy violations, region sprawl, and insecure public IP exposure.

Governance is deployed **before** any networking or compute workloads are created so that guardrails are actively enforced from Day 1.

---

## 2. When, Where, and Why

| Aspect | Detail |
|---|---|
| **Where** | Scoped at the Azure Tenant Root and Management Group level above subscriptions. |
| **When** | First execution after remote state storage bootstrap. Re-run only when organization hierarchy or corporate compliance policies evolve. |
| **Why** | Guarantees inheritance. Any subscription moved into `Landing Zones/Prod` automatically inherits all guardrails without manual subscription configuration. |

---

## 3. Code Walkthrough: File by File

### `backend.tf`
- **Terraform Engine (`>= 1.5.0`) & Provider (`azurerm ~> 3.110`)**: Standardizes provider versions to ensure consistent plan evaluation across environments.
- **Backend Configuration**:
  ```hcl
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatew4gika"
    container_name       = "tfstate"
    key                  = "governance.tfstate"
    use_azuread_auth     = true
  }
  ```
  - Stores state in the dedicated blob `governance.tfstate`.
  - **`use_azuread_auth = true`**: Enforces Entra ID authentication (OIDC) rather than requiring long-lived storage access keys.

---

### `variables.tf`
Defines the customization points for governance:
- **`alz_root_id` / `alz_root_name`** (`default = "alz-enterprise"`): Unique identifier and display name for the top-level container below Tenant Root.
- **`parent_management_group_id`** (`default = null`): Defaults to Tenant Root Group (`/providers/Microsoft.Management/managementGroups/<tenant-id>`).
- **`allowed_locations`** (`default = ["eastus", "eastus2", "centralus"]`): List of approved geographic regions to enforce data residency and cost containment.
- **`enable_deny_public_ip`** (`default = true`): Enforces policy blocking public IP attachments to workload network interfaces.
- **`mandatory_tag_name`** (`default = "Environment"`): Enforces tag presence on resource groups for FinOps auditing.

---

### `main.tf`
Calls two child modules:

#### 1. Management Groups Module Call (Lines 2–8)
```hcl
module "management_groups" {
  source = "../../modules/management_groups"

  alz_root_id                = var.alz_root_id
  alz_root_name              = var.alz_root_name
  parent_management_group_id = var.parent_management_group_id
}
```
- Instantiates the CAF tree:
  - Root: `alz-enterprise`
  - Branches: `Platform` (Management, Connectivity, Identity) and `Landing Zones` (Dev, Test, Prod).

#### 2. Policy Assignment Module Call (Lines 11–18)
```hcl
module "policy_assignment" {
  source = "../../modules/policy_assignment"

  management_group_id   = module.management_groups.landing_zones_id
  allowed_locations     = var.allowed_locations
  enable_deny_public_ip = var.enable_deny_public_ip
  mandatory_tag_name    = var.mandatory_tag_name
}
```
- Targets the `Landing Zones` Management Group ID emitted dynamically by `module.management_groups`.
- Policies assigned here automatically apply to all child environments (`dev`, `test`, `prod`) without touching platform management groups.

---

### `outputs.tf`
Exposes the created Management Group IDs and Policy Assignment IDs:
- `alz_root_management_group_id`, `platform_management_group_id`, `landing_zones_management_group_id`
- `workloads_dev_management_group_id`, `workloads_test_management_group_id`, `workloads_prod_management_group_id`
- `allowed_locations_policy_id`, `deny_public_ip_policy_id`

These outputs enable platform orchestration and external verification scripts.

---

### `terraform.tfvars` & `terraform.tfvars.example`
Provide real input values for non-default runs, allowing customization of allowed regions or disabling strict public IP denial during transitional migrations.
