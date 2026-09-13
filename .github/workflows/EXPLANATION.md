# GitHub Actions Workflows (`.github/workflows`) — Detailed Explanation

## 1. Overview & Purpose

The `.github/workflows/` directory contains the automated **CI/CD pipelines** that govern testing, security validation, and deployment of the Azure Landing Zone infrastructure.

Every workflow uses **OpenID Connect (OIDC) Workload Identity Federation** to authenticate directly to Azure without storing long-lived service principal client secrets in GitHub.

---

## 2. CI/CD Architecture & Security Flow

```text
[Pull Request Created]
       │
       ▼
[terraform-ci.yml]
  ├── Step 1: terraform fmt -check (Syntax validation)
  ├── Step 2: terraform validate across all layers (Schema checks)
  ├── Step 3: tfsec & Checkov security static analysis (IaC SAST)
  └── Step 4: terraform plan (Hub Layer via OIDC) -> Posts plan summary to PR
       │
  (PR Reviewed & Merged into main)
       │
       ▼
[deploy-governance.yml]  --> Deploys Layer 0: Management Groups & Policies
       │
       ▼
[deploy-hub.yml]         --> Deploys Layer 1: Hub VNet, Firewall, Bastion
       │
       ▼
[deploy-spokes.yml]      --> Deploys Layer 2: Dev, Test, and Prod Spokes
```

---

## 3. Workflows Walkthrough: File by File

### 1. `terraform-ci.yml` (Pull Request Validation)
- **Trigger**: Pull requests targeting `main` touching `**/*.tf` or `**/*.tfvars`.
- **Jobs**:
  1. `lint-and-validate`:
     - Checks code formatting via `terraform fmt -check`.
     - Initializes each layer (`00-governance`, `01-connectivity-hub`, `02-spokes`) in backend-agnostic mode and runs `terraform validate`.
     - Runs **tfsec** and **Checkov** to audit against CIS Azure Foundations benchmarks.
  2. `plan-hub`:
     - Requests an OIDC JSON Web Token (JWT) using `id-token: write`.
     - Authenticates via `azure/login@v2`.
     - Runs `terraform plan` against the Hub layer and leaves an automated PR comment summarizing planned adds/changes/deletions.

### 2. `deploy-governance.yml` (Layer 0 Deployment)
- **Trigger**: Push to `main` with changes in `layers/00-governance/**` or `modules/management_groups/**`, `modules/policy_assignment/**`. Also supports `workflow_dispatch` manual trigger.
- **Workflow**: Runs `terraform plan -out=tfplan`, then gated apply. Deploys CAF hierarchy and baseline policies.

### 3. `deploy-hub.yml` (Layer 1 Deployment)
- **Trigger**: Push to `main` touching `layers/01-connectivity-hub/**` or Hub modules (`azure_firewall`, `bastion`, `vpn_gateway`).
- **Gating**: Uses GitHub Environment `production` with required manual reviewer approvals before `terraform apply` executes.

### 4. `deploy-spokes.yml` (Layer 2 Deployment)
- **Trigger**: Push to `main` touching `layers/02-spokes/**` or spoke modules.
- **Matrix Strategy**: Deploys across `dev`, `test`, and `prod` spoke environments in parallel or sequence based on environment targets.

---

## 4. OIDC Authentication Deep-Dive

In all deployment workflows, authentication is handled via federated credentials:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Azure Login (OIDC)
    uses: azure/login@v2
    with:
      client-id: ${{ secrets.AZURE_CLIENT_ID }}
      tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

### Why OIDC Over Service Principal Passwords?
1. **Zero Secret Storage:** No passwords or client secrets exist in GitHub Secrets. There is no password to expire, leak, or rotate every 90 days.
2. **Short-Lived Ephemeral Tokens:** GitHub's OIDC provider issues a signed token valid for only a few minutes. Azure Entra ID validates the signature and exchanges it for an Azure access token.
3. **Strict Subject Validation:** Entra ID verifies the token's `sub` claim (e.g., `repo:priyanshu-singh-sengar/azure-landing-zone-capstone:ref:refs/heads/main`). Workflows running from unauthorized branches or forks are rejected immediately.
