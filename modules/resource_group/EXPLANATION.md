# Resource Group Module (`modules/resource_group`) — Detailed Explanation

## 1. Overview & Purpose

The `resource_group` module encapsulates the creation of **Azure Resource Groups** (`azurerm_resource_group`) and automatically injects standardized metadata tags.

In Azure, a Resource Group is the lifecycle and administrative boundary for all child resources.

---

## 2. Key Design Decisions

### Minimal & Idiomatic Resource Declaration
```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
```

1. **Zero Boilerplate:** Avoids artificial lifecycle hacks and volatile timestamps (`timestamp()`), ensuring predictable plans and fast execution.
2. **Direct Tag Passthrough:** Inherits caller-provided tags directly without redundant merging.

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
