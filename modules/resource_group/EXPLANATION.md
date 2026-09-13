# Resource Group Module (`modules/resource_group`) — Detailed Explanation

## 1. Overview & Purpose

The `resource_group` module encapsulates the creation of **Azure Resource Groups** (`azurerm_resource_group`) and automatically injects standardized metadata tags.

In Azure, a Resource Group is the lifecycle and administrative boundary for all child resources.

---

## 2. Key Design Decisions

### Automated Tag Injection & Lifecycle Guard
```hcl
tags = merge(
  {
    IaC_Managed = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  },
  var.tags
)

lifecycle {
  ignore_changes = [
    tags["CreatedAt"]
  ]
}
```

1. **`IaC_Managed = "Terraform"`**: Automatically stamped on every resource group to track IaC ownership.
2. **`CreatedAt` with `ignore_changes`**: Captures the initial date of provisioning. Without `ignore_changes = [tags["CreatedAt"]]`, every subsequent `terraform apply` would detect `timestamp()` changing and attempt to update tags unnecessarily.

---

## 3. Inputs & Outputs

### Inputs (`variables.tf`)
- `name`: Resource group name (e.g., `rg-hub-prod-01`, `rg-spoke-dev-01`).
- `location`: Azure region (e.g., `eastus`).
- `tags`: Map of caller-supplied tags (`Environment`, `Project`, etc.).

### Outputs (`outputs.tf`)
- `id`: Resource ID of the resource group.
- `name`: Name of the resource group.
- `location`: Region of the resource group.
