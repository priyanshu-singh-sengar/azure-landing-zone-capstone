# Azure Landing Zone — Hub-Spoke Infrastructure Capstone Project

This repository contains the Infrastructure as Code (IaC) implementation for an Enterprise Azure Landing Zone based on a Hub-and-Spoke Topology.

## Documentation & Reference Files
- [ARCHITECTURE_DESIGN_AND_REPO_STRUCTURE.md](./ARCHITECTURE_DESIGN_AND_REPO_STRUCTURE.md): Target Architecture & Repo Design
- [EXPLANATION.md](./EXPLANATION.md): Deep-dive explanation on the design decisions and component rationales.

---

## Architecture Highlights
- **Governance**: Hierarchical Management Group structure with Azure Policy guardrails (Allowed Regions, Mandatory Tags, Allowed Resource Types).
- **Hub Network (`10.0.0.0/16`)**:
  - Central **Azure Firewall** (`10.0.3.0/24`) for filtered egress and traffic inspection.
  - **Azure Bastion** (`10.0.2.0/26`) for clientless, secure administrative access without public IPs.
  - **VPN / ExpressRoute Gateway** (`10.0.1.0/24`) for hybrid connectivity to on-premises datacenters.
- **Spoke Networks**:
  - **DEV Spoke (`10.1.0.0/16`)**
  - **TEST Spoke (`10.2.0.0/16`)**
  - **PROD Spoke (`10.3.0.0/16`)**
- **Traffic Routing**: User-Defined Routes (UDR) routing `0.0.0.0/0` through Azure Firewall private IP (`10.0.3.4`).

---

## Repository Structure
```text
landingZone/
├── ARCHITECTURE_DESIGN_AND_REPO_STRUCTURE.md # Detailed Architecture & Design Proposal
├── README.md                                 # Overview & Quickstart
├── EXPLANATION.md                            # Comprehensive Component Deep-Dive & Justifications
├── .gitignore                                # Git ignore rules for Terraform & secrets
├── bootstrap/                                # AzureRM Remote State Storage Setup
├── modules/                                  # Reusable Terraform child modules
│   ├── management_groups/
│   ├── policy_assignment/
│   ├── resource_group/
│   ├── vnet/
│   ├── nsg/
│   ├── route_table/
│   ├── vnet_peering/
│   ├── azure_firewall/
│   ├── bastion/
│   └── vpn_gateway/
└── layers/                                   # Environment and infrastructure layers
    ├── 00-governance/                        # Management Groups & Policies
    ├── 01-connectivity-hub/                  # Hub VNet, Firewall, Bastion, Gateway
    └── 02-spokes/                            # Dev, Test, Prod Spokes & Peering
```

---

## Quickstart & Deployment Guide

### Prerequisites
- [Terraform](https://www.terraform.io/) `>= 1.5.0`
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) `>= 2.50.0`
- Active Azure Subscription with Owner or User Access Administrator rights (for Management Group and Policy assignments).

```bash
# Login to your Azure account
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### Layered Deployment Order
Deploy the layers sequentially to satisfy network and governance dependencies:

#### 1. Tier 0 — Governance & Policy Guardrails
```bash
cd layers/00-governance
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### 2. Tier 1 — Connectivity Hub (Firewall, Bastion, Gateway)
```bash
cd ../01-connectivity-hub
terraform init
terraform plan -var-file="environments/hub.tfvars"
terraform apply -var-file="environments/hub.tfvars"
```

#### 3. Tier 2 — Workload Spokes (DEV, TEST, PROD)
```bash
cd ../02-spokes

# Deploy DEV Spoke (10.1.0.0/16)
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy TEST Spoke (10.2.0.0/16)
terraform plan -var-file="environments/test.tfvars"
terraform apply -var-file="environments/test.tfvars"

# Deploy PROD Spoke (10.3.0.0/16)
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

---

## CI/CD Automation (GitHub Actions)

Pre-configured workflows in `.github/workflows/`:
- **`terraform-ci.yml`**: End-to-end CI/CD pipeline:
  - **Pull Request**: Runs `terraform fmt -check`, static validation on all layers, security scanning (`tfsec` + `Checkov`), runs `terraform plan` for the target layer via Azure OIDC, and comments the formatted plan directly on the PR.
  - **Push to `main`**: Gated `terraform apply` job using Azure OIDC federated identity, requiring manual environment approval through GitHub's `production` environment.
- **`deploy-governance.yml`**: Dispatches manual plan/apply for Management Groups and Policy assignments via OIDC.
- **`deploy-hub.yml`**: Dispatches manual plan/apply for Hub Connectivity infrastructure via OIDC.
- **`deploy-spokes.yml`**: Matrix deployment pipeline supporting selective or parallel rollout across `dev`, `test`, and `prod` environments via OIDC.

### Azure OIDC Authentication Setup
Workflows use passwordless OpenID Connect (OIDC) authentication. The following GitHub repository secrets must be configured:
- `AZURE_CLIENT_ID`: App registration / Service Principal Application ID
- `AZURE_TENANT_ID`: Azure Active Directory Directory (Tenant) ID
- `AZURE_SUBSCRIPTION_ID`: Target Azure Subscription ID

Federated credentials must be granted to:
- `repo:<org-or-user>/<repo>:ref:refs/heads/main`
- `repo:<org-or-user>/<repo>:pull_request`
- `repo:<org-or-user>/<repo>:environment:production`
