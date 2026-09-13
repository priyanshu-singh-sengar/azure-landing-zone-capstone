# modules/

## Purpose

This directory contains all reusable Terraform modules. A module is a self-contained unit of infrastructure that can be called multiple times with different inputs. Instead of writing the same Azure resource blocks in multiple places, each resource pattern is encapsulated in a module and called from the relevant layer.

---

## Module Conventions

Every module follows the same file structure:

- `main.tf`: Resource definitions. The only entry point for actual Azure API calls.
- `variables.tf`: Input declarations. Every input has a `type` and `description`. Sensitive inputs are marked with `sensitive = true`.
- `outputs.tf`: Output declarations. Only exposes values that callers need (IDs, names, private IPs). Avoids exposing the full resource object to limit coupling.

Modules declare `required_providers` in their own `main.tf` to document provider dependencies, but they do not declare a `backend` block. State is always owned by the calling layer.

---

## Modules in This Directory

| Module | What It Deploys |
|---|---|
| `azure_firewall/` | Public IP, Firewall Policy, default rule collection, Azure Firewall instance |
| `bastion/` | Public IP, Azure Bastion Host |
| `management_groups/` | Full ALZ Management Group hierarchy (7 groups) |
| `nsg/` | Network Security Group with configurable rules |
| `policy_assignment/` | Azure Policy assignments at Management Group scope |
| `resource_group/` | Azure Resource Group |
| `route_table/` | Route Table with configurable routes |
| `vnet/` | Virtual Network, Subnets, NSG associations, Route Table associations |
| `vnet_peering/` | Bi-directional VNet peering pair |
| `vpn_gateway/` | Public IP, Virtual Network Gateway |

Refer to each module's own directory for detailed documentation.

---

## Design Decisions

**Why not use the Terraform Registry modules (e.g., `Azure/network/azurerm`)?**

Community registry modules are general-purpose and accept dozens of variables for flexibility. They introduce external dependencies and may change in ways that break your code. For a Landing Zone where consistency and auditability are critical, custom modules with opinionated defaults are preferable. Every module in this directory is under version control and changes only when explicitly updated.

**Why do modules not use data sources to look up external resources?**

Cross-module data sources create hidden dependencies that make the code harder to reason about and test. Instead, required external values (like the Hub VNet ID) are passed explicitly as variables. This makes the dependency visible at the call site and allows modules to be tested in isolation with synthetic inputs.

**Tag inheritance**

All modules merge a standard `IaC_Managed = "Terraform"` tag with the caller-supplied `var.tags`. This ensures that every resource in the estate has this tag regardless of what the caller passes in. Resources without this tag were created outside Terraform.
