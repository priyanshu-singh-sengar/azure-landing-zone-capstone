# layers/00-governance/

## Purpose

This is the first deployment layer. It creates the Management Group hierarchy and assigns Azure Policy to enforce governance controls across all workload subscriptions before any infrastructure is deployed. Running this layer first ensures that every subsequent resource deployed into the Landing Zone immediately inherits the required security and compliance controls.

---

## Files

### main.tf

Contains two module calls:

**`module "management_groups"`**

Calls `modules/management_groups` to create the full ALZ Management Group hierarchy under the tenant root. The hierarchy follows the Microsoft CAF recommended structure:

```
Enterprise ALZ Root
├── Platform
│   ├── Management
│   ├── Connectivity
│   └── Identity
├── Landing Zones
│   ├── Dev
│   ├── Test
│   └── Prod
├── Sandboxes
└── Decommissioned
```

The `landing_zones_id` output from this module is passed directly into the policy assignment module.

**`module "policy_assignment"`**

Calls `modules/policy_assignment` to assign three Azure built-in policies at the `Landing Zones` Management Group. Policies assigned here propagate automatically to all Dev, Test, and Prod child groups without requiring individual assignments.

---

### variables.tf

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `alz_root_id` | string | `alz-enterprise` | The identifier for the root Management Group |
| `alz_root_name` | string | `Enterprise ALZ Root` | Display name for the root Management Group |
| `parent_management_group_id` | string | `null` | Parent group; null places it under the Tenant Root Group |
| `allowed_locations` | list(string) | `["eastus","eastus2","centralus"]` | Regions where resources are permitted |
| `enable_deny_public_ip` | bool | `true` | Whether to assign the deny-public-IP-on-NIC policy |
| `mandatory_tag_name` | string | `Environment` | Tag name to enforce on all resources |

---

### outputs.tf

Exposes the IDs of the management groups for external reference or cross-layer use.

---

### backend.tf

Configures the AzureRM remote state backend:
- Storage account: `sttfstatew4gika` (created by bootstrap)
- Container: `tfstate`
- Key: `governance.tfstate`
- `use_azuread_auth = true`: Authentication uses the Azure AD token from OIDC, not a storage account access key.

---

### terraform.tfvars / terraform.tfvars.example

Contains the actual values used at apply time. The `.example` file provides a template without sensitive or environment-specific values, safe to commit to version control.

---

## Deployment

```bash
cd layers/00-governance
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

This layer has no dependency on other layers and can be applied at any time, including before the hub or spokes exist.

---

## Why This Layer Runs First

Policies are evaluated at resource creation time. If the "deny public IP on NIC" policy is assigned after spoke VMs are created, existing VMs are not retroactively denied — they are flagged as non-compliant. Deploying governance first ensures that everything deployed afterward is subject to the policy from its first creation.
