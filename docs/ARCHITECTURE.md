# Azure Enterprise Landing Zone — Architecture Reference

## Table of Contents

1. [What is an Azure Landing Zone?](#1-what-is-an-azure-landing-zone)
2. [Project Overview](#2-project-overview)
3. [Repository Structure](#3-repository-structure)
4. [Layered Deployment Model](#4-layered-deployment-model)
5. [Hub-and-Spoke Network Topology](#5-hub-and-spoke-network-topology)
6. [IP Address Plan](#6-ip-address-plan)
7. [Governance and Policy Layer](#7-governance-and-policy-layer)
8. [Security Design](#8-security-design)
9. [CI/CD Pipeline Architecture](#9-cicd-pipeline-architecture)
10. [OIDC Authentication — Deep Dive](#10-oidc-authentication--deep-dive)
11. [Remote State Management](#11-remote-state-management)
12. [Terraform Module Design](#12-terraform-module-design)
13. [Technologies Used](#13-technologies-used)
14. [Design Decisions and Alternatives](#14-design-decisions-and-alternatives)
15. [How Everything Ties Together](#15-how-everything-ties-together)
16. [Portal Navigation Guide](#16-portal-navigation-guide)

---

## 1. What is an Azure Landing Zone?

An Azure Landing Zone (ALZ) is a well-architected, pre-configured Azure environment that serves as the foundation for hosting workloads. It addresses common enterprise requirements — security, compliance, connectivity, identity, and governance — before any application is deployed. Think of it as "paving the road" so that every application team that lands in the environment inherits sensible defaults automatically.

### Core Principles

**Scale without complexity.** A Landing Zone is designed so that adding a new workload (a new spoke) does not require re-engineering the shared services. The Hub is provisioned once; spokes are added by convention.

**Security by default.** Rather than trusting workload teams to implement security correctly, the Landing Zone enforces it through Azure Policy, Network Security Groups, User-Defined Routes, and a centralised firewall. Non-compliant resources are blocked or flagged automatically.

**Governance at scale.** Management Groups provide a hierarchical container above subscriptions. Policies assigned at a Management Group level propagate down to every subscription underneath it, without needing to touch each subscription individually.

**Prescriptive, not restrictive.** The Landing Zone defines how shared infrastructure works (routing, DNS, identity) but does not dictate how workload teams build their applications inside their spoke.

### Microsoft ALZ Design Areas

Microsoft defines eight design areas for a Landing Zone: Azure Billing/Tenant, Identity and Access Management, Resource Organisation, Network Topology, Security, Management, Governance, and Platform Automation. This project implements the network, governance, resource organisation, and platform automation design areas.

---

## 2. Project Overview

This repository provisions an Enterprise Azure Landing Zone using Terraform and GitHub Actions. It implements a hub-and-spoke network topology with centralised security, three-tier workload isolation, and a fully automated CI/CD pipeline that authenticates to Azure without storing any long-lived credentials.

### What Gets Deployed

| Layer | Resources |
|---|---|
| Bootstrap | Resource Group, Storage Account, Blob Container for Terraform remote state |
| Governance (Layer 00) | Management Group hierarchy, Azure Policy assignments |
| Connectivity Hub (Layer 01) | VNet (10.0.0.0/16), Azure Firewall (Standard), Azure Bastion (Standard), VPN Gateway (VpnGw1AZ), NSGs |
| Workload Spokes (Layer 02) | Per-environment VNets, three-tier NSGs (web/app/db), UDR forcing all egress via Hub Firewall, VNet peering |

---

## 3. Repository Structure

```
landingZone/
├── bootstrap/                   # One-time setup: creates Terraform state storage account
├── layers/
│   ├── 00-governance/           # Management Groups and Azure Policy — deployed first
│   ├── 01-connectivity-hub/     # Shared networking layer — deployed second
│   └── 02-spokes/               # Per-environment workload networks — deployed last
├── modules/                     # Reusable Terraform modules (called by layers)
│   ├── azure_firewall/
│   ├── bastion/
│   ├── management_groups/
│   ├── nsg/
│   ├── policy_assignment/
│   ├── resource_group/
│   ├── route_table/
│   ├── vnet/
│   ├── vnet_peering/
│   └── vpn_gateway/
├── .github/
│   ├── workflows/
│   │   ├── terraform-ci.yml     # Lint, validate, plan on PR; gated apply on push to main
│   │   ├── deploy-governance.yml
│   │   ├── deploy-hub.yml
│   │   └── deploy-spokes.yml    # Matrix-based deployment across dev/test/prod
│   ├── dependabot.yml           # Automated security updates for GitHub Actions
│   └── ISSUE_TEMPLATE/
└── docs/                        # Documentation
```

### Why This Structure?

**Layers separate concern and deployment order.** Governance must exist before networking (so policy can evaluate it). Networking must exist before spokes (because spokes peer to the hub). The numbered prefix (`00-`, `01-`, `02-`) makes the required deployment order self-documenting.

**Modules enforce consistency.** Instead of writing inline `azurerm_virtual_network` resources in every layer, the `vnet` module is called by each layer. Every VNet in the estate follows the same pattern: same NSG association logic, same route table association logic, same tag inheritance.

**Bootstrap is separate.** The storage account that holds Terraform state cannot be managed by Terraform itself (circular dependency). The bootstrap directory creates it with local state, then the main layers reference it as a remote backend.

---

## 4. Layered Deployment Model

The project uses a strict deployment order enforced by convention and by the CI/CD pipeline.

```
Bootstrap → Layer 00 (Governance) → Layer 01 (Hub) → Layer 02 (Spokes)
```

### Why Layered Instead of a Single Root Module?

A single monolithic Terraform root module would:
- Cause slow plan/apply cycles (Azure Firewall alone takes 10–15 minutes to provision).
- Increase the blast radius of a state corruption event.
- Prevent different teams from owning different layers independently.
- Make it impossible to update governance policies without touching networking code.

Separate layers each have their own state file, apply cycle, and required inputs.

### Layer 00 — Governance

Runs first. Creates Management Groups and assigns Azure Policy. Has no network dependencies.

### Layer 01 — Connectivity Hub

Runs second. Deploys all shared networking resources into `rg-hub-prod-01`. Outputs the Hub VNet ID, Hub VNet name, resource group name, and Azure Firewall private IP. These are consumed by Layer 02.

### Layer 02 — Spokes

Runs last, once per environment (dev, test, prod). Consumes Hub outputs via `.tfvars` files. Creates the spoke VNet, peers it to the Hub, and applies the UDR that forces all traffic through the Hub Firewall.

---

## 5. Hub-and-Spoke Network Topology

### Concept

The Hub-and-Spoke topology is the standard enterprise network pattern on Azure. One central Hub VNet hosts all shared services. Multiple Spoke VNets host workloads. Spokes connect to the Hub through VNet peering but do not connect directly to each other — all inter-spoke and internet traffic passes through the Hub.

```
                    Internet
                        |
                   [Azure Firewall]   <- All egress inspected here
                        |
              ┌─────────────────────┐
              │     Hub VNet        │
              │  10.0.0.0/16        │
              │  GatewaySubnet      │ <- VPN/ExpressRoute
              │  BastionSubnet      │ <- Browser-based SSH/RDP
              │  FirewallSubnet     │ <- Azure Firewall
              │  SharedSvcSubnet    │ <- DNS, monitoring
              └─────────┬───────────┘
                        │ VNet Peering (bi-directional)
          ┌─────────────┼─────────────┐
          │             │             │
   [Dev Spoke]   [Test Spoke]   [Prod Spoke]
   10.1.0.0/16   10.2.0.0/16   10.3.0.0/16
```

### Why Hub-and-Spoke Instead of Flat VNet?

| Concern | Flat Single VNet | Hub-and-Spoke |
|---|---|---|
| Security boundary | All workloads share one | Each spoke is an isolated zone |
| Blast radius | One breach can reach everything | Spoke breach is contained |
| Scalability | VNet size limits apply globally | Each spoke scales independently |
| On-premises connectivity | One gateway for all (no sharing) | Gateway transit shares one gateway |

### VNet Peering Key Settings

- `allow_forwarded_traffic = true`: Allows traffic that did not originate in the peered VNet (required for spoke-to-internet via hub firewall).
- `allow_gateway_transit = true` on the hub side: Lets the hub share its VPN Gateway with spokes.
- `use_remote_gateways = true` on the spoke side: Tells the spoke to use the hub VPN Gateway.

Peering is always bidirectional — two resources are created per peering.

### User-Defined Routes (Forced Tunnelling)

The `spoke_route_table` overrides Azure's default system route for internet traffic:

```
Destination: 0.0.0.0/0
Next Hop Type: VirtualAppliance
Next Hop IP: <Azure Firewall private IP>
```

Every packet leaving a spoke subnet goes through the Azure Firewall for inspection.

---

## 6. IP Address Plan

| Scope | CIDR | Purpose |
|---|---|---|
| Hub VNet | 10.0.0.0/16 | Shared services |
| GatewaySubnet | 10.0.1.0/24 | VPN Gateway |
| AzureBastionSubnet | 10.0.2.0/26 | Bastion (Azure requires /26 minimum) |
| AzureFirewallSubnet | 10.0.3.0/26 | Firewall |
| AzureFirewallManagementSubnet | 10.0.3.128/26 | Firewall management plane |
| snet-shared-svc | 10.0.4.0/24 | DNS, monitoring services |
| Dev Spoke VNet | 10.1.0.0/16 | Dev workloads |
| Test Spoke VNet | 10.2.0.0/16 | Test workloads |
| Prod Spoke VNet | 10.3.0.0/16 | Production workloads |

The supernet `10.0.0.0/8` is used in Firewall rules as the source for all internal traffic.

---

## 7. Governance and Policy Layer

### Management Group Hierarchy

```
Tenant Root Group
└── Enterprise ALZ Root  (alz-enterprise)
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

This mirrors the Microsoft Cloud Adoption Framework (CAF) recommended hierarchy.

### Policy Assignments (at Landing Zones Management Group)

1. **Allowed Locations**: Denies resource creation outside approved regions. Prevents data residency violations.
2. **Deny Public IP on NICs**: Blocks assigning public IPs to VM network interfaces. All access must flow through the Firewall or Bastion.
3. **Require Environment Tag**: Enforces that every resource carries an `Environment` tag. Enables cost allocation and governance reports.

### Why Built-in Policies?

Built-in policies are maintained by Microsoft, have stable definition IDs, and require no custom policy definition management. Custom policies are appropriate for organisation-specific controls but introduce maintenance overhead.

---

## 8. Security Design

### Defence in Depth

```
Layer 1: Azure Policy       -> Prevents non-compliant resources from being created
Layer 2: Azure Firewall     -> Inspects all egress; blocks unapproved destinations
Layer 3: NSGs               -> Enforce microsegmentation within each spoke
Layer 4: User-Defined Routes -> Forces all traffic through the firewall
Layer 5: Azure Bastion      -> Zero public SSH/RDP exposure on VMs
Layer 6: No Public IPs on VMs -> Policy-enforced at Management Group level
```

### Three-Tier Microsegmentation

Each spoke implements three subnet tiers:

- **snet-web**: Receives HTTP/HTTPS. Denied direct access from the database subnet.
- **snet-app**: Receives traffic only from web subnet on ports 8080/8443/5000. SSH/RDP from Bastion only. Denied all direct internet traffic.
- **snet-db**: SQL traffic (1433, 5432, 3306) from app subnet only. Denied traffic from web subnet. Denied all internet traffic.

A compromised web server cannot reach the database directly.

### Firewall Egress Rules

Azure Firewall allows:
- DNS (port 53) from `10.0.0.0/8`
- NTP (port 123) from `10.0.0.0/8`
- HTTP/HTTPS to `*.microsoft.com`, `*.azure.com`, `*.windowsupdate.com`, `*.ubuntu.com`, `github.com`

All other egress is denied (Azure Firewall has an implicit deny-all).

---

## 9. CI/CD Pipeline Architecture

### terraform-ci.yml

Triggers on pull requests and pushes to `main`.

**On Pull Request:**
1. `validate`: `terraform fmt -check`, `terraform validate` on all three layers, tfsec scan, Checkov scan.
2. `plan`: OIDC login, `terraform init`, `terraform plan` on hub layer, plan posted as PR comment.

**On Push to Main:**
1. `validate`: Same checks.
2. `apply`: Requires human approval in GitHub `production` Environment, then `terraform apply -auto-approve`.

### Layer-Specific Workflows

`deploy-governance.yml`, `deploy-hub.yml`, `deploy-spokes.yml` are manual (`workflow_dispatch`) workflows for deploying individual layers. The spokes workflow uses a GitHub Actions matrix strategy (`max-parallel: 1`) to deploy environments sequentially.

### Branch Protection

The `main` branch ruleset requires at least one approved code review and all CI checks to pass before merge.

---

## 10. OIDC Authentication — Deep Dive

### The Problem

Traditional CI/CD authentication stores a Service Principal client secret in GitHub Secrets. Secrets are long-lived, must be manually rotated, and if extracted, grant indefinite access to Azure.

### How OIDC Works

```
1. GitHub Actions job starts.
2. GitHub's OIDC provider issues a signed JWT containing:
   - Issuer: https://token.actions.githubusercontent.com
   - Subject: repo:owner/repo:environment:production (or ref/branch)
   - Audience: api://AzureADTokenExchange
3. The azure/login@v2 action sends this JWT to Azure AD.
4. Azure AD validates the JWT against the Federated Credential configuration on the Service Principal.
5. If the subject claim matches, Azure AD returns a short-lived (1-hour) access token.
6. Terraform uses this token (ARM_USE_OIDC=true) for all Azure API calls.
7. No secret is ever stored. The JWT is only valid for this specific job run.
```

### Federated Credentials Configured

| Credential | Subject | Purpose |
|---|---|---|
| PR validation | `repo:...:pull_request` | Plan jobs on PRs |
| Main push | `repo:...:ref:refs/heads/main` | Direct push validation |
| Production environment | `repo:...:environment:production` | Gated apply jobs |

### Why Not Managed Identity?

Managed Identities are for Azure-hosted compute. GitHub Actions runners are not Azure resources and cannot be assigned a Managed Identity. OIDC federated credentials are the equivalent mechanism for external systems.

### OIDC vs SP with Password

| Property | SP + Password | OIDC Federated |
|---|---|---|
| Secret storage | GitHub Secrets (long-lived) | No secret stored |
| Rotation | Manual | Not required |
| Scope binding | None — secret works from anywhere | JWT bound to specific repo/branch/environment |
| Audit trail | Actions logged by SP | Token subject ties action to exact job context |

---

## 11. Remote State Management

### Why Remote State?

Terraform state tracks deployed resources. Local state is lost when CI/CD runners terminate (they are ephemeral). Remote state enables:
- Persistent state across runner instances
- State locking (prevents concurrent applies)
- Team collaboration (shared authoritative state)

### Bootstrap Pattern

The `bootstrap/` directory creates the storage account using local state. Its outputs are hard-coded into each layer's `backend.tf`. This is the standard Terraform pattern for bootstrapping remote state.

### Storage Account Hardening

- GRS replication: State survives a regional outage
- Blob versioning: Every apply creates a new blob version; rollback by restoring a prior version
- Soft delete (30 days): Protects against accidental deletion
- TLS 1.2 minimum: Encrypted transport enforced
- `use_azuread_auth = true`: No storage access key used; authentication via Azure AD token (same OIDC token)

### State Locking

The AzureRM backend uses blob leases for locking. A concurrent `terraform apply` cannot acquire the lease and exits with a lock error. No additional configuration required.

---

## 12. Terraform Module Design

### Module Contract

Every module has:
- `variables.tf`: All inputs with types and descriptions.
- `main.tf`: All resource definitions. No cross-module data sources.
- `outputs.tf`: Only the values callers need (IDs, names, IPs).

Modules do not have their own `backend.tf`.

### Opinionated Defaults

Modules embed defaults that enforce standards:
- All resources get `IaC_Managed = "Terraform"` appended to tags.
- The VNet module always associates subnets with NSGs and route tables in the same call.
- The Firewall module always creates a Firewall Policy and attaches it.

### Conditional Resources

The `count` meta-argument enables optional resources:
- `enable_vpn_gateway = false`: No VPN Gateway (saves cost in dev/test).
- `enable_test_vm = false`: No validation VM.
- `enable_peering = false`: No VNet peering.

---

## 13. Technologies Used

| Technology | Version | Role |
|---|---|---|
| Terraform | >= 1.5.0 | Infrastructure as Code |
| AzureRM Provider | ~> 3.110 | Azure Resource Manager API |
| GitHub Actions | — | CI/CD orchestration |
| azure/login@v2 | v2 | OIDC authentication |
| hashicorp/setup-terraform@v3 | v3 | Terraform installation on runner |
| tfsec | v1.0.3 | Static IaC security analysis |
| Checkov | master | Policy-as-code security scanning |
| Azure Firewall | Standard SKU | Stateful L3–L7 inspection |
| Azure Bastion | Standard SKU | Browser-based SSH/RDP |
| Azure VPN Gateway | VpnGw1AZ | Site-to-site VPN (zone-redundant) |
| Azure Policy | Built-in | Governance guardrails |
| Azure Blob Storage | Standard GRS | Terraform remote state |
| OIDC (RFC 8693) | — | Secretless CI/CD authentication |

---

## 14. Design Decisions and Alternatives

### Terraform vs ARM Templates / Bicep

ARM Templates are verbose JSON. Bicep is Azure-only with a smaller ecosystem. Terraform is provider-agnostic, has mature state management, a rich module ecosystem, and is the industry standard for enterprise multi-cloud IaC. Bicep was considered and rejected due to its Azure-only scope.

### Firewall Standard vs Premium

Premium adds TLS inspection and IDPS at ~3x the cost. Standard provides FQDN-based filtering and stateful inspection sufficient for this environment. Premium is appropriate for regulated industries requiring TLS-level inspection.

### Azure Bastion vs Jump Box VM

A jump box has a public attack surface, requires patching, and adds SSH key management overhead. Azure Bastion is PaaS (Microsoft-managed), uses HTTPS port 443 only, and integrates with Azure AD for authentication.

### VNet Peering vs VPN Between Spokes and Hub

VPN adds 10–50ms latency, has per-GB transfer cost, and requires gateway configuration on both sides. VNet peering uses the Microsoft backbone with near-zero latency and no per-GB cost within the same region. VPN is appropriate only for cross-region or cross-tenant scenarios.

### Forced Tunnelling vs FQDN-Only Rules Without UDR

Without the UDR, Azure uses system routes and spoke internet traffic bypasses the firewall. The UDR ensures every packet is inspected regardless of destination. FQDN rules alone are insufficient without forcing traffic through the firewall.

---

## 15. How Everything Ties Together

### Control Plane Flow (Deployment)

```
Developer pushes to feature branch
  -> Opens Pull Request to main
  -> terraform-ci.yml: validate job (fmt, validate, tfsec, Checkov)
  -> terraform-ci.yml: plan job (OIDC login, terraform plan, post to PR comment)
  -> Human reviews PR and plan
  -> PR merged to main
  -> terraform-ci.yml: apply job (human approves in GitHub Environment)
  -> terraform apply runs against Azure
  -> State written to Azure Blob Storage
  -> Infrastructure live in rg-hub-prod-01
```

### Data Plane Flow (Runtime Traffic)

```
VM in Dev Spoke (snet-app) wants to reach api.microsoft.com
  -> Packet hits the route table on snet-app
  -> UDR: 0.0.0.0/0 -> Azure Firewall private IP
  -> Firewall evaluates application rules
  -> *.microsoft.com matches allow rule
  -> Packet exits via Firewall public IP
  -> Response returns, stateful tracking allows return traffic
```

```
Administrator needs SSH access to VM in snet-app
  -> Opens portal.azure.com -> Bastion -> Connect to VM
  -> Browser establishes WebSocket over HTTPS port 443 to Bastion
  -> Bastion opens SSH port 22 to VM private IP
  -> No public IP on VM, no port 22 open to internet
```

---

## 16. Portal Navigation Guide

### GitHub Portal

| What to View | Navigation |
|---|---|
| Workflow run logs | Repository -> Actions |
| PR plan comment | Repository -> Pull Requests -> [PR] -> Conversation |
| Environment approvals | Repository -> Settings -> Environments -> production |
| Branch protection rules | Repository -> Settings -> Rules -> Rulesets |
| Dependabot alerts | Repository -> Security -> Dependabot |
| GitHub Secrets | Repository -> Settings -> Secrets and variables -> Actions |

### Azure Portal

| What to View | Navigation |
|---|---|
| All hub resources | Resource Groups -> rg-hub-prod-01 |
| VNet peerings | rg-hub-prod-01 -> vnet-hub-prod-01 -> Peerings |
| Firewall rules | rg-hub-prod-01 -> afw-hub-prod-01 -> Rules |
| Bastion host | rg-hub-prod-01 -> bas-hub-prod-01 |
| Management Group hierarchy | portal.azure.com -> Management Groups |
| Policy assignments | Management Groups -> Landing Zones -> Policy |
| Policy compliance | portal.azure.com -> Policy -> Compliance |
| Remote state files | Resource Groups -> rg-terraform-state -> sttfstatew4gika -> Containers -> tfstate |
| OIDC federated credentials | Azure AD -> App registrations -> [SP] -> Certificates & secrets -> Federated credentials |
| VPN Gateway | rg-hub-prod-01 -> vpngw-hub-prod-01 |
| Spoke resources | Resource Groups (filter by rg-dev-, rg-test-, rg-prod-) |
