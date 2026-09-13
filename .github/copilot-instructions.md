# GitHub Copilot Instructions for Azure Landing Zone

## Project Overview
This repository contains a **Terraform Azure Landing Zone** using a **Hub-and-Spoke topology**. Code is organized into reusable child modules (`modules/`) consumed by layered root configurations (`layers/`).

## HCL Conventions

### Naming
- Resources: `kebab-case` using abbreviation prefixes: `rg-`, `vnet-`, `snet-`, `nsg-`, `afw-`, `bas-`, `rt-`, `vpngw-`
- Terraform identifiers (resource/variable names): `snake_case`
- Environment suffixes: `-dev-01`, `-test-01`, `-prod-01`, `-hub-prod-01`

### Module Structure
Every module must have exactly:
```
modules/<name>/
  main.tf        # Resources only, no provider/terraform blocks except in child modules that need them
  variables.tf   # All input variables with type, description, and default where applicable
  outputs.tf     # All useful resource attributes exposed as outputs
```

### Required Tags
All resources must include `tags = var.tags` merged with at minimum:
```hcl
tags = merge({ IaC_Managed = "Terraform" }, var.tags)
```

### Provider Version Pinning
Always pin provider versions with `~>` (pessimistic constraint):
```hcl
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 3.110"
  }
}
```

### Variable Defaults
- Always provide `type` and `description` for every variable
- Provide `default` only where the value is genuinely optional
- Never use `default = null` unless the resource attribute truly accepts null

### Security Requirements
- No hard-coded credentials, subscription IDs, or tenant IDs in code
- Use `sensitive = true` on password/secret outputs
- Prefer private endpoints over public access
- NSGs must explicitly deny traffic that is not required

### Formatting
- Always run `terraform fmt` before committing
- Use 2-space indentation
- Align `=` signs within the same block for readability

## Module Invocation Pattern
```hcl
module "example" {
  source = "../../modules/example"

  name                = var.example_name
  location            = var.location
  resource_group_name = module.rg.name
  tags                = var.tags
}
```

## Avoid
- Inline resource blocks within module calls
- `count` for anything other than feature flags (prefer `for_each` for maps)
- Outputting entire resource objects (output specific attributes)
- Using `latest` for image versions in VM resources
