# Layers Directory — Architecture, Execution Order & Design Patterns

## 1. Overview & Core Philosophy

The `layers/` directory is the core operational tier of this Azure Landing Zone repository. It separates cloud infrastructure into **independently deployable, decoupled tiers**, each with its own Terraform state file and blast radius:

```text
layers/
├── 00-governance          --> Layer 0: Management Groups & Azure Policies
├── 01-connectivity-hub    --> Layer 1: Hub VNet, Azure Firewall, Bastion, VPN Gateway
└── 02-spokes              --> Layer 2: Workload Spoke VNets (Dev, Test, Prod), Peering & UDRs
```

---

## 2. Why A Multi-Layer Model Instead of a Monolithic State?

In a naive Terraform repository, all resources (management groups, firewalls, VNets, and test VMs) are declared in one root directory sharing a single `terraform.tfstate`. While simple to start, this creates catastrophic problems in enterprise environments:

1. **Massive Blast Radius:** A typo or bug in a developer spoke module could accidentally trigger changes or deletion on the production Hub Firewall during `terraform apply`.
2. **State Locking Bottlenecks:** A single engineer running a 30-minute test deployment locks the entire state, preventing platform or network engineers from shipping critical fixes.
3. **Execution Time:** A single state containing hundreds of cloud resources takes 10+ minutes just to refresh status during `terraform plan`.
4. **RBAC & Separation of Duties:** Cloud Governance architects, Network Administrators, and Application Teams must not have identical privileges across all tiers.

By decoupling into `00-governance`, `01-connectivity-hub`, and `02-spokes`:
- Each layer runs in its own pipeline and maintains its own `.tfstate` blob.
- The blast radius is strictly contained.
- Layers communicate cleanly using **Terraform Remote State Data Sources** (`terraform_remote_state`).

---

## 3. Deployment Sequence & Dependencies

```text
[bootstrap]
     │ (Provisions Remote State Storage Account)
     ▼
[00-governance]
     │ (Sets up CAF Hierarchy & Guardrails: Allowed Regions, Deny Public IPs)
     ▼
[01-connectivity-hub]
     │ (Provisions Central Networking: Firewall 10.0.3.4, Bastion, Gateways)
     ▼
[02-spokes]
       (Provisions Dev, Test, Prod VNets, reads Hub outputs via remote state,
        creates VNet Peering to Hub, attaches UDR pointing 0.0.0.0/0 -> Firewall)
```

### Layer Dependency Matrix

| Layer | Depends On | Data Consumed | Outputs Provided |
|---|---|---|---|
| `00-governance` | `bootstrap` | Remote State Storage | Management Group IDs, Policy Assignment IDs |
| `01-connectivity-hub` | `00-governance` | Subscription & Policy compliance | Hub VNet ID, Hub Subnet IDs, Firewall Private IP (`10.0.3.4`), Gateway Transit capability |
| `02-spokes` | `01-connectivity-hub` | Hub VNet ID, Firewall Private IP | Spoke VNet IDs, Subnet IDs, Test VM Private IPs |

---

## 4. How Inter-Layer State Sharing Works

Layer `02-spokes` must know the Hub VNet ID (to configure VNet Peering) and the Azure Firewall's private IP (to configure the `0.0.0.0/0` next-hop in Route Tables).

Instead of hardcoding these values, `02-spokes` uses a **read-only remote state data source**:

```hcl
data "terraform_remote_state" "hub" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "01-connectivity-hub.tfstate"
  }
}
```

This ensures that whenever the Hub is deployed or updated, the Spokes layer automatically reads the dynamic IP and resource IDs without manual intervention or risky string concatenation.

---

## 5. Folder Directory Breakdown

- **[00-governance/EXPLANATION.md](file:///d:/az400/landingZone/layers/00-governance/EXPLANATION.md)**: Management Group hierarchy, subscription organization, and Azure Policy enforcement definitions.
- **[01-connectivity-hub/EXPLANATION.md](file:///d:/az400/landingZone/layers/01-connectivity-hub/EXPLANATION.md)**: Central network backbone, Azure Firewall rules, Azure Bastion, and VPN Gateway.
- **[02-spokes/EXPLANATION.md](file:///d:/az400/landingZone/layers/02-spokes/EXPLANATION.md)**: Dev, Test, and Prod spoke isolation, 3-tier subnets, NSG evaluation, and forced tunneling UDR.
