# .github/workflows/

## Purpose

This directory contains all GitHub Actions workflow files. Together they implement the CI/CD pipeline that validates, plans, and applies Terraform changes to Azure. Every workflow authenticates to Azure using OIDC federated credentials — no long-lived secrets are stored.

---

## Workflow Files

### terraform-ci.yml — Primary CI/CD Pipeline

**Triggers:** Pull requests to `main`, pushes to `main`, manual dispatch.

**Job: `validate` (runs on every trigger)**

1. Checkout code.
2. Install Terraform 1.5.7.
3. `terraform fmt -check -recursive`: Verifies all `.tf` files are formatted per Terraform canonical style. Fails the job on any formatting issue.
4. `terraform init -backend=false && terraform validate` for each of the three layers: Validates HCL syntax and resource references without connecting to Azure or the remote backend.
5. `tfsec-action@v1.0.3`: Runs Aqua Security's tfsec static analysis. Reports security misconfigurations. `soft_fail: true` means findings are reported but do not block the pipeline.
6. `checkov-action@master`: Runs Bridgecrew's Checkov. Same soft-fail behaviour.

**Job: `plan` (runs on pull_request events only)**

1. Azure Login via OIDC (`azure/login@v2` with the PR federated credential).
2. `terraform init`: Initialises the hub layer with the remote AzureRM backend.
3. `terraform plan -var-file="environments/hub.tfvars"`: Generates an execution plan. Output is captured with `tee plan-output.txt`.
4. Posts the plan output as a comment on the PR using `github-script`. Output is truncated at 60,000 characters if it exceeds GitHub's comment limit.

The plan comment gives reviewers visibility into exactly what Azure changes will be applied when the PR is merged. This is critical for infrastructure code reviews.

**Job: `apply` (runs on push to `main` after validate passes)**

Conditions: `github.ref == 'refs/heads/main'` AND event is `push` or `workflow_dispatch`.

1. Requires approval in the `production` GitHub Environment (enforced by `environment: production` in the job definition). The job pauses here until a listed reviewer approves.
2. Azure Login via OIDC (production environment federated credential).
3. `terraform init` and `terraform apply -auto-approve` on the hub layer.

**OIDC permissions block**

```yaml
permissions:
  id-token: write    # Required: allows GitHub to request an OIDC token
  contents: read     # Required: allows checking out the repository
  pull-requests: write  # Required: allows posting PR comments
```

The `id-token: write` permission is mandatory. Without it, GitHub will not issue a JWT token to the workflow, and the OIDC exchange with Azure AD will fail.

---

### deploy-governance.yml — Governance Layer Deployment

**Trigger:** Manual only (`workflow_dispatch`) with `action` input (plan or apply).

**Purpose:** Deploys `layers/00-governance` on demand. Used for initial setup and when management group or policy changes are needed independently of the CI pipeline.

**Key behaviour:** Uses the `production` GitHub Environment for gating even on manual runs, ensuring governance changes require approval.

---

### deploy-hub.yml — Hub Layer Deployment

**Trigger:** Manual only with `action` input.

**Purpose:** Deploys `layers/01-connectivity-hub`. Useful when hub networking changes need to be applied independently (e.g., adding a new subnet, adjusting firewall rules).

**Plan-then-apply:** Runs `terraform plan -out=tfplan` first, then `terraform apply tfplan` if `action == 'apply'`. Using the plan file ensures the apply executes exactly the changes that were planned, not a new plan that might differ.

---

### deploy-spokes.yml — Spoke Environments Deployment

**Trigger:** Manual with `target_env` (dev/test/prod/all) and `action` (plan/apply) inputs.

**Matrix preparation job:** A `matrix-prep` job runs first. It evaluates the `target_env` input and writes the appropriate environment list to `GITHUB_OUTPUT`. If `target_env = "all"`, it outputs `["dev", "test", "prod"]`. Otherwise, it outputs a single-element list.

**Matrix deployment job:** The `spokes` job uses `strategy.matrix.env` populated from the prep job's output. `max-parallel: 1` ensures environments deploy sequentially: dev before test before prod. Running them in parallel would risk a shared state file corruption.

---

### dependabot.yml — Automated Security Updates

Located at `.github/dependabot.yml` (not in workflows/). Configures Dependabot to scan GitHub Actions action references weekly and open PRs when new versions are available. This ensures `actions/checkout`, `azure/login`, `hashicorp/setup-terraform`, and the security scanners stay up to date and are not pinned to versions with known vulnerabilities.
