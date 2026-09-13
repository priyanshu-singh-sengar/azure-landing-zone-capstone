# Interview Questions — Azure Enterprise Landing Zone

This document covers the most frequently asked interview questions related to this project. Each answer is written to reflect actual implementation decisions made in this codebase, not generic textbook answers.

---

## Section 1: Azure Landing Zones

**Q: What is an Azure Landing Zone and why do organisations use them?**

An Azure Landing Zone is a pre-configured Azure environment that enforces security, compliance, connectivity, identity, and governance before any workload is deployed. Organisations use them because it is significantly harder to retrofit security controls onto existing infrastructure than to build them in from the start. A Landing Zone means that when an application team spins up resources, those resources automatically inherit network isolation, policy guardrails, consistent tagging, and centralised egress inspection — without the app team having to know anything about those controls.

**Q: What are the design areas of an Azure Landing Zone?**

Microsoft defines eight: Azure Billing and Tenant, Identity and Access Management, Resource Organisation (Management Groups and subscriptions), Network Topology and Connectivity, Security, Management (monitoring, cost, backups), Governance (policy), and Platform Automation (IaC). This project implements Resource Organisation, Network Topology, Security, Governance, and Platform Automation.

**Q: What is the difference between a Landing Zone and a regular Azure subscription?**

A raw Azure subscription has no guardrails by default. You can create any resource in any region, attach public IPs to VMs, skip tags, and deploy resources with no network isolation. A Landing Zone subscription sits within a Management Group hierarchy that has Azure Policy applied. Policy controls what can and cannot be deployed. The subscription is also peered into the hub network, so traffic is automatically inspected by the centralised firewall. The subscription inherits these controls through its position in the hierarchy.

**Q: What is the Azure Cloud Adoption Framework (CAF) and how does this project relate to it?**

The CAF is Microsoft's documented guidance for adopting Azure at enterprise scale. It covers strategy, planning, migration, governance, and management. The Landing Zone accelerator (also called the ALZ reference implementation) is the technical output of CAF's Ready phase. This project implements the core CAF patterns: the recommended Management Group hierarchy (with Platform, Landing Zones, Sandboxes, and Decommissioned groups), the hub-and-spoke network topology, and the governance guardrails (policy assignments for location, public IP, and tagging).

---

## Section 2: Hub-and-Spoke Networking

**Q: Explain the hub-and-spoke network topology.**

The hub is a central VNet that hosts shared infrastructure: the firewall, VPN gateway, Bastion, and DNS. Spoke VNets host workloads (dev, test, prod). Spokes connect to the hub through VNet peering. Spokes do not peer to each other, so inter-spoke traffic must traverse the hub, where it is inspected by the firewall. This creates a consistent security choke point and avoids the complexity of managing N*(N-1) peering relationships between every pair of spokes.

**Q: What is VNet peering and how does it differ from VPN?**

VNet peering creates a direct, low-latency connection between two Azure VNets over the Microsoft backbone. Traffic does not traverse the public internet and has no per-GB transfer cost within the same region. A VNet-to-VNet VPN, by contrast, creates an encrypted tunnel through VPN Gateways on both sides, adds 10–50ms of latency, has a per-GB transfer cost, and requires gateway provisioning on both ends. We use peering between hub and spokes because of the performance and cost advantages. VPN is appropriate for cross-region or cross-tenant connectivity.

**Q: What is gateway transit and why is it used?**

Gateway transit is a VNet peering option that allows a spoke VNet to use the VPN Gateway hosted in the hub VNet. Without this, each spoke would need its own VPN Gateway, which is expensive (~$130–300/month each). With gateway transit enabled on the hub side and `use_remote_gateways` set on the spoke side, all spokes share a single VPN Gateway in the hub. This is a cost-saving measure and simplifies on-premises connectivity configuration.

**Q: What is a User-Defined Route (UDR) and why is it critical in this design?**

By default, Azure applies system routes that allow VMs to reach the internet directly. A UDR overrides these system routes with custom ones. In this project, every spoke subnet has a route table attached with a single rule: `0.0.0.0/0 -> VirtualAppliance -> Azure Firewall private IP`. This forces all egress traffic through the firewall for inspection. Without this UDR, VMs would bypass the firewall and reach the internet directly, defeating the security architecture.

**Q: What is the difference between `allow_forwarded_traffic` and `allow_gateway_transit` in VNet peering?**

`allow_forwarded_traffic` permits traffic that did not originate in the peered VNet to be forwarded through the peering. This is required for the spoke-to-internet flow, because traffic from a spoke VM arrives at the hub firewall (it did not originate in the hub VNet) and must be forwarded out.

`allow_gateway_transit` (set on the hub) tells the hub to make its VPN Gateway available to the peered VNets. `use_remote_gateways` (set on the spoke) tells the spoke to use the remote gateway from the peered VNet rather than having its own.

---

## Section 3: Security

**Q: What is defence in depth and how is it implemented here?**

Defence in depth means applying multiple, independent security controls so that defeating one control does not give an attacker access to everything. In this project:
- Azure Policy prevents non-compliant resources from being created at all.
- The Azure Firewall inspects and filters all egress traffic.
- NSGs enforce microsegmentation — the web tier cannot talk directly to the database tier.
- UDRs ensure traffic cannot bypass the firewall.
- Azure Bastion eliminates public SSH/RDP endpoints entirely.
- Policy blocks public IPs on VM NICs.

An attacker who compromises a web server is still blocked from the database by the NSG on the app and database subnets.

**Q: What is microsegmentation and how is it implemented in the spokes?**

Microsegmentation divides a network into small, isolated segments so that a breach in one segment does not propagate to others. In this project, each spoke has three subnets: web, app, and database. NSG rules enforce:
- Web subnet receives HTTP/HTTPS from outside, but cannot initiate traffic to the database subnet.
- App subnet receives traffic only from the web subnet on application ports. SSH/RDP only from the Bastion subnet.
- Database subnet receives SQL traffic only from the app subnet. Direct traffic from the web subnet is explicitly denied.

**Q: Why is Azure Bastion used instead of a jump box VM?**

A jump box is a VM with a public IP that administrators SSH into first, then SSH from there to internal VMs. Problems with jump boxes: they have a public IP exposed to the internet on port 22 or 3389 (a direct attack surface), they require OS patching and maintenance, and SSH key management adds complexity. Azure Bastion is a PaaS service managed by Microsoft, accessible only over HTTPS port 443 from a browser, and does not require any open ports on target VMs. The Standard SKU also supports native SSH/RDP clients through tunnelling, eliminating the browser-only restriction.

**Q: What Azure Firewall SKU tiers exist and what is the difference?**

There are three tiers:
- **Basic**: Lowest cost, supports network rules and basic FQDN filtering, no policy support for complex rules. Suitable for simple scenarios.
- **Standard**: Supports FQDN-based application rules, threat intelligence, network and NAT rules, and Firewall Policy. Used in this project.
- **Premium**: Adds TLS inspection (decrypts and re-encrypts HTTPS to inspect payload), IDPS (signature-based intrusion detection), URL categories, and web categories. Required for compliance-heavy environments like banking or healthcare.

**Q: What is the difference between an NSG and an Azure Firewall?**

NSGs are stateless (they evaluate each packet independently), work at Layer 4 (IP/port), are applied at the subnet or NIC level, and have no logging without additional configuration. Azure Firewall is stateful (tracks connection state), can inspect up to Layer 7 (FQDN, URL, TLS in Premium tier), is a centralised service, and has built-in logging to Azure Monitor and Log Analytics. NSGs provide microsegmentation within a VNet; Azure Firewall provides centralised inspection of all traffic traversing the hub.

---

## Section 4: Governance

**Q: What are Azure Management Groups?**

Management Groups are containers above subscriptions in the Azure resource hierarchy. A subscription can belong to one Management Group. A Management Group can contain subscriptions and other Management Groups, forming a tree up to six levels deep. Azure Policy and RBAC assignments made at a Management Group level are inherited by all subscriptions beneath it. This enables governance at scale without touching each subscription individually.

**Q: What is Azure Policy and how does it work?**

Azure Policy defines rules about what can and cannot exist in Azure. A policy definition specifies a condition (e.g., "resource has no Environment tag") and an effect (Audit, Deny, DeployIfNotExists, Modify). A policy assignment applies a definition to a scope (Management Group, subscription, or resource group). In this project, three policies are assigned at the Landing Zones Management Group: allowed locations (Deny effect — blocks deployment to unapproved regions), no public IPs on NICs (Deny effect — blocks non-compliant NICs), and require Environment tag (Deny effect — blocks untagged resources). The Deny effect means the Azure Resource Manager API call fails at creation time.

**Q: What is the difference between a policy definition and a policy assignment?**

A policy definition specifies the rule and its effect. It is a template. A policy assignment applies that definition to a specific scope, optionally with parameters. For example, the "Allowed locations" definition accepts a list of location names as a parameter. The assignment supplies that list (`eastus`, `eastus2`, `centralus`) and applies it to the Landing Zones Management Group. The same definition can be assigned multiple times to different scopes with different parameters.

**Q: What is the Microsoft CAF management group hierarchy?**

The recommended hierarchy is:
- Tenant Root Group (Azure's default top-level group)
- ALZ Root (your organisation's top-level group)
  - Platform (subscriptions for shared infrastructure)
    - Management (Log Analytics, Automation)
    - Connectivity (Hub networking)
    - Identity (Active Directory Domain Services)
  - Landing Zones (workload subscriptions)
    - Dev / Test / Prod (per-environment)
  - Sandboxes (experimentation, no prod data)
  - Decommissioned (subscriptions being retired)

This structure is used directly in the `management_groups` module.

---

## Section 5: Terraform

**Q: What is Terraform remote state and why is it important?**

Terraform state is a JSON file that maps Terraform resource addresses to real Azure resources. If state is stored locally, it is lost when CI/CD runners terminate (they are ephemeral containers). Remote state stores the file in a persistent location (Azure Blob Storage in this project). Additionally, the AzureRM backend acquires a blob lease during `terraform apply`, preventing two concurrent applies from corrupting the state file (state locking).

**Q: What is the bootstrap pattern in Terraform?**

The circular dependency problem: Terraform cannot manage its own state storage because it needs state storage to manage anything. The bootstrap pattern resolves this by creating the state storage account using a one-time local apply, then configuring all subsequent layers to use that storage account as their remote backend. The bootstrap `main.tf` creates a resource group, storage account (with GRS, versioning, soft delete), and a blob container.

**Q: What is the difference between `count` and `for_each` in Terraform?**

`count` creates N copies of a resource, indexed numerically. Resources are addressed as `resource.name[0]`, `resource.name[1]`, etc. Removing an element in the middle of a `count` list causes Terraform to re-index and potentially destroy/recreate later elements.

`for_each` creates one resource per key in a map or set. Resources are addressed as `resource.name["key"]`. Removing one key only removes that one resource. This project uses `for_each` in the NSG module (`for_each = { for rule in var.security_rules : rule.name => rule }`) and in the VNet module for subnets, NSG associations, and route table associations.

**Q: What is a Terraform module and when should you use one?**

A module is a directory of `.tf` files that can be called from other Terraform code using a `module` block. Use a module when the same pattern of resources is needed in multiple places. In this project, `modules/nsg` is called six times across the hub and spoke layers. Without the module, the same NSG resource and security rule resource block would be duplicated six times with slight variations. The module ensures all NSGs follow the same pattern.

**Q: What is `terraform validate` and what does it check?**

`terraform validate` checks that the configuration is syntactically correct and internally consistent. It verifies that required variables are declared, that resource type names are valid, that module inputs match their variable declarations, and that references to attributes exist. It does not contact the Azure API. In the CI pipeline, `terraform init -backend=false` is used before validate so that it runs without needing access to the remote state backend.

**Q: What does `terraform fmt -check` do?**

`terraform fmt` formats Terraform code according to the canonical style (proper indentation, aligned equals signs in attribute assignments). Running it with `-check` instead of applying the format changes makes it return a non-zero exit code if any file is not properly formatted. This is used in the CI pipeline as a style enforcement gate — a PR with unformatted code fails the validate job.

**Q: What is the `depends_on` argument and when is it needed?**

Terraform automatically determines resource creation order from implicit dependencies (references between resources). `depends_on` adds an explicit dependency when one resource depends on another that is not referenced in its configuration. In this project, `peering_2_to_1` (spoke-to-hub peering) has `depends_on = [azurerm_virtual_network_peering.peering_1_to_2]` because Azure requires the hub-to-spoke peering to exist before the spoke-to-hub peering can be created, but there is no natural reference between the two peering resources.

---

## Section 6: CI/CD and GitHub Actions

**Q: Explain the pipeline flow from PR to production.**

1. Developer opens a PR against `main`.
2. `terraform-ci.yml` validate job runs: format check, validate (all three layers), tfsec, Checkov.
3. Plan job runs: OIDC login to Azure, `terraform init` (connects to remote state), `terraform plan`, output posted as PR comment.
4. A human reviewer approves the PR after reviewing both the code diff and the plan comment.
5. PR is merged to `main`.
6. The apply job is triggered but requires human approval in the GitHub `production` Environment.
7. A designated approver clicks Approve in the GitHub UI.
8. `terraform apply -auto-approve` runs.
9. Terraform writes updated state to Azure Blob Storage.

**Q: What is a GitHub Environment and how is it used for gating deployments?**

A GitHub Environment is a deployment target with its own secrets, variables, and protection rules. In this project, the `production` environment has required reviewers configured. When a GitHub Actions job specifies `environment: production`, it pauses and waits for a listed reviewer to approve before proceeding. This ensures no infrastructure is deployed to production without a human authorisation step, even if all automated checks pass.

**Q: What is the matrix strategy used in the spokes workflow?**

The `deploy-spokes.yml` workflow uses a matrix to deploy multiple environments from a single job definition. A prep job generates a list of environments (e.g., `["dev", "test", "prod"]`) and writes it to the job output. The `spokes` job then runs once per environment in the matrix, with `max-parallel: 1` to ensure they deploy sequentially (so dev completes before test starts). Each iteration uses `${{ matrix.env }}` to select the correct `.tfvars` file (`environments/dev.tfvars`, etc.).

**Q: What is tfsec and what does it check?**

tfsec is a static analysis tool for Terraform code. It checks for common security misconfigurations: unencrypted storage accounts, overly permissive security group rules, missing HTTPS enforcement, publicly accessible resources, etc. It runs without connecting to Azure — it only reads the `.tf` source files. In this pipeline, it is set to `soft_fail: true`, meaning it reports findings but does not fail the pipeline, allowing teams to review findings without blocking deployment.

**Q: What is Checkov?**

Checkov (by Bridgecrew/Palo Alto) is a policy-as-code framework that scans IaC files against a library of security and compliance policies. It supports Terraform, ARM, Bicep, Kubernetes, and more. Like tfsec, it runs statically. It covers a broader set of frameworks and supports custom policies defined in Python. In this pipeline it also runs with `soft_fail: true`.

---

## Section 7: OIDC and Identity

**Q: What is OpenID Connect?**

OpenID Connect is an identity layer built on top of OAuth 2.0. OAuth 2.0 handles authorisation (granting access to resources). OIDC adds authentication (proving who you are) by introducing the ID Token, a signed JWT that contains claims about the authenticated entity. In the CI/CD context, GitHub's OIDC provider acts as the identity provider, and Azure AD acts as the relying party (resource server).

**Q: What is a JWT and what does it contain?**

A JSON Web Token (JWT) is a signed, base64-encoded token with three parts: header (algorithm and token type), payload (claims), and signature. In the OIDC flow, the JWT issued by GitHub contains:
- `iss` (issuer): `https://token.actions.githubusercontent.com`
- `sub` (subject): Identifies the specific workflow context, e.g., `repo:owner/repo:environment:production`
- `aud` (audience): `api://AzureADTokenExchange`
- `exp` (expiration): Short-lived
- Other claims: repository, branch, run ID, job ID, etc.

Azure AD validates the signature using GitHub's public keys and then checks the `sub` claim against the configured federated credential.

**Q: What is a Federated Credential in Azure AD?**

A Federated Credential is a trust relationship configured on an Azure AD Application (Service Principal) that tells Azure AD: "if you receive a token from issuer X with subject claim Y, treat it as proof of identity for this Service Principal." It replaces client secrets or certificates as the authentication mechanism. The Service Principal never has a password — it relies entirely on this trust relationship.

**Q: What is the difference between Service Principal authentication and Managed Identity?**

A Service Principal is an Azure AD application registration used to represent a non-human identity. It can authenticate with a client secret, a certificate, or a federated credential (OIDC). A Managed Identity is an Azure-managed Service Principal automatically assigned to Azure resources (VMs, App Service, AKS pods). Managed Identities have no credentials to manage — Azure rotates them automatically. However, Managed Identities only work for Azure-hosted resources. GitHub Actions runners are not Azure resources, so Managed Identity is not applicable; federated OIDC credentials are used instead.

---

## Section 8: General Azure and Cloud

**Q: What is the difference between RBAC and Azure Policy?**

RBAC (Role-Based Access Control) controls who can do what (write, read, delete) on Azure resources. It operates on the control plane — who can call the Azure API. Azure Policy controls what can exist — it evaluates the properties of resources being created or already existing. RBAC says "this user can create VMs." Azure Policy says "VMs must not have public IPs." They are complementary controls.

**Q: What is Azure Resource Manager (ARM) and how does Terraform interact with it?**

Azure Resource Manager is the unified management plane for all Azure resources. Every operation — creating a VM, setting a tag, querying a VNet — goes through the ARM API. Terraform's AzureRM provider makes HTTP calls to the ARM API using an Azure AD access token. The provider translates Terraform HCL resource definitions into ARM API calls. When `ARM_USE_OIDC=true`, the provider performs the OIDC token exchange to get that access token instead of using a client secret.

**Q: What is geo-redundant storage (GRS) and why is it used for Terraform state?**

GRS replicates data synchronously within a primary region (three copies) and then asynchronously to a secondary region hundreds of miles away. If the primary region has an outage, Azure can fail over to the secondary. Terraform state is the source of truth for deployed infrastructure. Losing it would require a complex state reconstruction process. GRS ensures state availability even during a regional failure.

**Q: What is Azure Firewall DNS proxy mode?**

When DNS proxy is enabled on Azure Firewall, VMs in the VNet can use the Firewall's private IP as their DNS server. The Firewall forwards DNS queries and logs them. This enables FQDN-based network rules to work correctly — without DNS proxy, the Firewall cannot resolve FQDNs in network rules because it does not see the DNS query. In this project, `enable_dns_proxy = true` is set in the `azure_firewall` module call.

**Q: What is the AzureFirewallManagementSubnet and when is it required?**

The management subnet is required when using the Azure Firewall Basic SKU. It provides a dedicated out-of-band management channel for the firewall control plane, keeping management traffic separate from data plane traffic. For Standard and Premium SKUs, it is optional. In this project, the management subnet is provisioned in the hub VNet to allow switching to Basic SKU for cost optimisation without network reconfiguration.

---

## Section 9: Best Practices

**Q: What are Landing Zone best practices?**

1. **Separate platform and workload subscriptions.** Platform subscriptions (hub networking, shared services) should be separate from workload subscriptions (dev, test, prod). This isolates billing, limits blast radius, and allows different teams to own different subscriptions.

2. **Use Management Groups for inheritance.** Apply policies and RBAC at the Management Group level. Never configure individual subscriptions manually.

3. **Network everything through the hub.** All egress should traverse the centralised firewall. No spoke should have a direct internet breakout.

4. **Enforce tagging from day one.** Retroactive tag enforcement is painful. Apply a "require tag" policy early.

5. **Use Azure Bastion, not jump boxes.** Eliminate public IPs on management VMs.

6. **Store Terraform state remotely.** Always use a remote, locked backend in production.

7. **Never store credentials in code or secrets.** Use OIDC federated credentials for CI/CD.

8. **Enable versioning on state storage.** Blob versioning allows rollback if state is corrupted.

9. **Use IaC for everything.** No manual portal changes. Manual changes cause drift — Terraform will try to revert them on the next apply.

10. **Test with `terraform plan` before apply.** Always review the plan output, especially in production. The `plan` job on PRs enforces this workflow.
