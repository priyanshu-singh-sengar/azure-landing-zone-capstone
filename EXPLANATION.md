# Azure Landing Zone — Comprehensive Technical Reference & Explanation
**A Detailed Guide on the "When, Where, and Why" of Every Component and Design Decision**

---

## Table of Contents
1. [Overview & Core Philosophy](#1-overview--core-philosophy)
2. [Why Hub-and-Spoke Topology?](#2-why-hub-and-spoke-topology)
3. [Governance & Policy Layer](#3-governance--policy-layer)
   - [Management Group Hierarchy](#management-group-hierarchy)
   - [Azure Policy Guardrails](#azure-policy-guardrails)
4. [Hub Network Components](#4-hub-network-components)
   - [Azure Firewall](#azure-firewall)
   - [Azure Bastion Host](#azure-bastion-host)
   - [VPN / ExpressRoute Gateway](#vpn--expressroute-gateway)
   - [Shared Services Subnet](#shared-services-subnet)
5. [Spoke Networks (DEV, TEST, PROD)](#5-spoke-networks-dev-test-prod)
   - [Environment Isolation](#environment-isolation)
   - [Subnet Tiering (Web, App, Data)](#subnet-tiering-web-app-data)
   - [Network Security Groups (NSGs)](#network-security-groups-nsgs)
   - [User-Defined Routes (UDR) & Route Tables](#user-defined-routes-udr--route-tables)
6. [Network Peering & Gateway Transit](#6-network-peering--gateway-transit)
7. [Repository Structure & Terraform Design Patterns](#7-repository-structure--terraform-design-patterns)
   - [Why Terraform for IaC?](#why-terraform-for-iac)
   - [Why Separate Child Modules?](#why-separate-child-modules)
   - [Why Layered Deployments & Decoupled State?](#why-layered-deployments--decoupled-state)
8. [Summary Cheat Sheet: When, Where & Why Table](#8-summary-cheat-sheet-when-where--why-table)

---

## 1. Overview & Core Philosophy

When building cloud infrastructure for an enterprise, the primary goal is not just to "make it work," but to build a foundation that is **secure, compliant, cost-efficient, and easy to maintain as the organization scales**.

This reference guide explains in plain, rigorous terms **what** each component does, **when** you should use it, **where** it lives in the architecture, and **why** it was chosen over alternative approaches.

---

## 2. Why Hub-and-Spoke Topology?

```text
                  +--------------------------------+
                  |         On-Premises            |
                  +---------------+----------------+
                                  | (VPN / ExpressRoute)
                                  v
+--------------------------------------------------------------------+
|                             HUB VNET                               |
|   [VPN/ER Gateway]   [Azure Bastion]   [Azure Firewall (10.0.3.4)] |
+-------------------+---------------------------------+--------------+
                    |                                 |
                    | (VNet Peering)                  | (VNet Peering)
                    v                                 v
          +-------------------+             +-------------------+
          |     DEV SPOKE     |             |    PROD SPOKE     |
          |  (10.1.0.0/16)    |             |   (10.3.0.0/16)   |
          +-------------------+             +-------------------+
```

### The Alternatives Considered
1. **Single Flat VNet:** All applications, servers, databases, and environments share subnets inside one large virtual network.
2. **Full Mesh (Everything Peered to Everything):** Every VNet is peered directly with every other VNet.
3. **Hub-and-Spoke Topology:** A central "Hub" manages routing, security, and hybrid connections, while separate "Spokes" host workloads.

### When to Use:
- When you host multiple environments (DEV, TEST, PROD) or multiple application teams that need network separation.
- When you need centralized security inspection (firewall) for all internet-bound and cross-premises traffic.

### Where is it Used:
- Across the entire cloud footprint; it forms the backbone of the enterprise network.

### Why Are We Using It?
* **Cost Efficiency:** Services like Azure Firewall (~$900+/mo) and VPN Gateways are expensive. Rather than deploying a separate firewall or gateway in DEV, TEST, and PROD, we centralize them once in the Hub and share them across all spokes.
* **Perimeter Security (Zero Trust):** By forcing all spoke outbound traffic to funnel through the Hub Firewall, security teams can inspect packets, block malware, log URLs, and prevent data exfiltration in one central place.
* **Blast Radius Containment:** A compromise in the DEV spoke cannot cross over into the PROD spoke because spokes do not peer with each other directly.

---

## 3. Governance & Policy Layer

### Management Group Hierarchy

#### Where:
Above the subscriptions in Azure Resource Manager (ARM).

#### When:
Used from Day 1 to organize Azure subscriptions into logical, manageable tiers before any resource is deployed.

#### Why:
* **Inheritance:** In Azure, permissions (RBAC) and guardrails (Policies) assigned to a parent Management Group automatically cascade down to all child subscriptions and resource groups.
* **Separation of Platform vs. Application Workloads:**
  - The `Platform` management group houses central network and shared services.
  - The `Landing Zones` management group houses application subscriptions (DEV, TEST, PROD).
* **Speed with Safety:** Platform teams configure policies once at the Management Group level. Development teams can then be granted Subscription Contributor rights within their spoke subscription without any risk of them altering firewall configurations or disabling auditing.

---

### Azure Policy Guardrails

#### Where:
Assigned at the Management Group or Subscription level.

#### When:
Enforced continuously during `terraform apply`, Azure CLI commands, Portal actions, and automated drift scans.

#### Key Policies Used & Why:
1. **Allowed Locations (e.g., `eastus`, `centralus`):**
   - *Why:* Prevents developers from deploying resources in expensive or non-compliant geographic regions (e.g., data residency compliance like GDPR/HIPAA).
2. **Allowed Resource Types:**
   - *Why:* Restricts provisioning of unapproved, high-cost resources (such as expensive N-series GPU VMs or unmanaged storage services).
3. **Mandatory Resource Tags (`Environment`, `CostCenter`, `Owner`, `ManagedBy`):**
   - *Why:* FinOps and cost attribution. When finance asks who is spending money on a cluster, tags provide immediate accountability.
4. **Deny Public IP on Spoke Network Interfaces (NICs):**
   - *Why:* **Critical Security Control.** A developer must never attach a public IP directly to a backend VM or container. Ingress must come through a controlled gateway (App Gateway / WAF) and egress must go through Azure Firewall.

---

## 4. Hub Network Components

```text
Hub VNet (10.0.0.0/16)
 ├── GatewaySubnet (10.0.1.0/24)          --> VPN / ExpressRoute Gateway
 ├── AzureBastionSubnet (10.0.2.0/26)      --> Azure Bastion Host
 ├── AzureFirewallSubnet (10.0.3.0/24)     --> Azure Firewall (IP: 10.0.3.4)
 └── snet-shared-svc (10.0.4.0/24)         --> Private DNS Zones, KMS, Tooling
```

### Azure Firewall
* **Where:** In the Hub VNet inside a dedicated subnet strictly named `AzureFirewallSubnet` (`10.0.3.0/24`).
* **When:** Whenever workloads in spokes need to communicate with the Internet (egress), communicate with on-premises networks, or communicate with other spokes.
* **Why:**
  - **Stateful Packet Inspection:** Unlike basic NSGs (which only check source/destination IP and port), Azure Firewall performs stateful Layer 3 to Layer 7 inspection.
  - **FQDN Filtering:** Allows rules like `allow outbound to *.github.com` or `*.ubuntu.com` for package downloads, rather than opening wide IP ranges that change constantly.
  - **Centralized Threat Intelligence:** Alerts on and automatically drops traffic to known malicious IPs and botnet domains.

---

### Azure Bastion Host
* **Where:** In the Hub VNet inside a dedicated subnet strictly named `AzureBastionSubnet` (minimum `/26` required).
* **When:** Whenever engineers, sysadmins, or DevOps operators need to RDP (Windows) or SSH (Linux) into virtual machines in any spoke.
* **Why:**
  - **Zero Public IPs Required on VMs:** VMs remain strictly private on the internal network.
  - **No Jumpbox Maintenance:** Traditional "Jumpbox" VMs require constant OS patching, virus scanning, and maintenance. Bastion is a fully managed PaaS service by Microsoft.
  - **Browser-Based HTML5 Connectivity:** Access occurs through the Azure Portal or Azure CLI tunnel over secure TLS port 443. RDP/SSH ports (3389/22) are never exposed to the public Internet, defeating brute-force attacks.

---

### VPN / ExpressRoute Gateway
* **Where:** In the Hub VNet inside a dedicated subnet strictly named `GatewaySubnet` (`10.0.1.0/24`).
* **When:** Whenever cross-premises connectivity is needed between the on-premises corporate office/datacenter and the Azure cloud.
* **Why:**
  - **Site-to-Site (S2S) IPsec VPN:** Provides an encrypted tunnel over public internet for cost-effective hybrid connectivity.
  - **ExpressRoute:** Provides dedicated, private, high-throughput, low-latency connectivity bypassing the public internet for enterprise workloads.
  - **Centralized Termination:** Having one gateway in the Hub avoids purchasing and configuring separate gateways in every spoke.

---

### Shared Services Subnet
* **Where:** In the Hub VNet (`snet-shared-svc`, `10.0.4.0/24`).
* **When:** For platform tooling that all environments require.
* **Why:**
  - Houses Azure Private DNS Resolver, domain controllers (if Active Directory is extended to Azure), self-hosted CI/CD build agents (Azure DevOps / GitHub Actions runners), and monitoring endpoints.

---

## 5. Spoke Networks (DEV, TEST, PROD)

### Environment Isolation
* **Where:** Distinct Virtual Networks:
  - `vnet-spoke-dev-01` (`10.1.0.0/16`)
  - `vnet-spoke-test-01` (`10.2.0.0/16`)
  - `vnet-spoke-prod-01` (`10.3.0.0/16`)
* **When:** When deploying application workloads.
* **Why:**
  - **True Boundary Isolation:** Putting DEV and PROD in separate VNets ensures that a misconfigured routing table or rogue test script in DEV cannot saturate network bandwidth or communicate with PROD databases without explicit firewall approval.
  - **Independent Lifecycles:** Development environments can be torn down, re-provisioned, or updated without any risk to production uptime.

---

### Subnet Tiering (Web, App, Data)

Within each Spoke, subnets are split by architecture tier:
1. `snet-web` (`10.x.1.0/24`): Frontend web apps, ingress reverse proxies.
2. `snet-app` (`10.x.2.0/24`): Microservices, APIs, backend application compute.
3. `snet-data` (`10.x.3.0/24`): Databases (SQL MI, PostgreSQL, CosmosDB private endpoints).

#### Why Multi-Tiering?
- **Defense in Depth (Microsegmentation):** Web servers do not need direct access to raw database files; they talk to the App tier. NSGs enforce that only the App subnet can initiate connections to the Data subnet on port 1433/5432.

---

### Network Security Groups (NSGs)
* **Where:** Associated with every individual subnet in the spoke VNets.
* **When:** Evaluated on every incoming and outgoing packet at the subnet boundary.
* **Why:**
  - Acts as a local Layer 4 stateful firewall.
  - Enforces the principle of least privilege: default deny all inbound, only allow traffic from specifically designated subnets and ports.

---

### User-Defined Routes (UDR) & Route Tables

```text
[Spoke VM] ---> Packet sent to external destination (e.g. 8.8.8.8)
                   |
                   v (Default Azure System Route would go direct to Internet)
             [Route Table / UDR: 0.0.0.0/0 -> Next Hop: 10.0.3.4]
                   |
                   v (FORCED HOOK)
          [Azure Firewall in Hub: 10.0.3.4] ---> [Filtered Internet Egress]
```

* **Where:** Attached to every subnet in every spoke VNet.
* **When:** Every time a resource inside a spoke initiates a connection.
* **Why:**
  - **Azure Default Behavior:** By default, Azure routes internet-bound traffic from any VM directly to the internet through default system routes.
  - **The Fix with UDR:** We add a route:
    - **Address Prefix:** `0.0.0.0/0` (All traffic)
    - **Next Hop Type:** `VirtualAppliance`
    - **Next Hop IP:** `10.0.3.4` (The private IP of Azure Firewall)
  - This is known as **forced tunneling**. It ensures no packet can bypass security inspection.

---

## 6. Network Peering & Gateway Transit

### VNet Peering
* **What:** Connects two VNets using Microsoft’s high-speed private backbone network (not traversing the public Internet).
* **Where:** Between Hub VNet and each Spoke VNet (`Hub <-> Dev`, `Hub <-> Test`, `Hub <-> Prod`).

### Key Peering Flags Explained:
1. `allow_gateway_transit = true` (Configured on the **Hub** side):
   - *Why:* Tells Azure that spoke VNets are permitted to route through the Hub's VPN Gateway to reach on-premises networks.
2. `use_remote_gateways = true` (Configured on the **Spoke** side):
   - *Why:* Allows spoke workloads to utilize the Hub’s gateway without needing a gateway in the spoke itself.
3. `allow_forwarded_traffic = true`:
   - *Why:* Allows traffic forwarded by an NVA (Azure Firewall) to flow freely between peered networks.

---

## 7. Repository Structure & Terraform Design Patterns

```text
landingZone/
├── modules/           --> Reusable building blocks (Zero hardcoded values)
└── layers/            --> Execution tiers with independent state files
    ├── 00-governance
    ├── 01-connectivity-hub
    └── 02-spokes
```

### Why Terraform for IaC?
- Declarative syntax (`HCL`) means you describe the *desired state*, and Terraform figures out the dependency graph, provisioning order, and deltas.
- Provides reliable state tracking and preview capability (`terraform plan`) before committing changes.

### Why Separate Child Modules?
- **DRY (Don't Repeat Yourself):** The VNet module is written once. It is instantiated 4 times (Hub, Dev, Test, Prod) using different inputs (`cidr_block`, `subnet_prefixes`).
- **Standardization:** Company naming conventions and mandatory tagging logic are embedded inside the modules, preventing individual engineers from forgetting compliance rules.

### Why Layered Deployments & Decoupled State?
A common mistake in beginner Terraform setups is putting the entire infrastructure into a single `main.tf` with one state file.

#### The Risk of a Monolithic State:
- If a developer makes a syntax error or breaking change while deploying a dev spoke, running `terraform apply` could lock, corrupt, or accidentally modify the production hub firewall.
- Blast radius is huge.

#### Our Layered Approach:
1. `00-governance`: Run once or rarely by Cloud Architects. Sets up Management Groups and Policies.
2. `01-connectivity-hub`: Managed by Network/Platform Engineers. Deploys Firewall, Bastion, Gateway.
3. `02-spokes`: Managed by DevOps/App teams. Deploys workload VNets and peerings.

**Result:** A change in the DEV spoke physically cannot touch the Hub or Governance state files.

---

## 8. Summary Cheat Sheet: When, Where & Why Table

| Component | Where Does It Live? | When Do We Use It? | Why Was It Chosen Over Alternatives? |
| :--- | :--- | :--- | :--- |
| **Management Groups** | Above Subscriptions (Tenant Root) | Multi-subscription enterprise organization | Enables centralized policy & RBAC inheritance without configuring individual subscriptions. |
| **Azure Policy** | Management Group scope | Continuous compliance & auditing | Hard guardrail that prevents unauthorized regions, unapproved SKUs, and missing tags. |
| **Hub VNet** | Central Connectivity Subscription (`10.0.0.0/16`) | Core shared infrastructure | Eliminates duplicate expensive gateways and centralizes routing. |
| **Azure Firewall** | `AzureFirewallSubnet` (`10.0.3.4`) | All spoke outbound & spoke-to-spoke traffic | Stateful L7 inspection, FQDN filtering, threat intelligence; superior to basic port-based NSGs. |
| **Azure Bastion** | `AzureBastionSubnet` (`10.0.2.0/26`) | Remote administration (RDP/SSH) | Clientless browser access over TLS; eliminates exposed public IPs and jumpbox maintenance. |
| **VPN Gateway** | `GatewaySubnet` (`10.0.1.0/24`) | Hybrid connection to on-premises | Secure IPsec tunnel sharing across all spokes via Gateway Transit. |
| **Spoke VNets** | Workload Subscriptions (`10.1`, `10.2`, `10.3`) | App hosting (DEV, TEST, PROD) | Strict environment boundary and lifecycle independence; zero cross-contamination. |
| **UDR (Route Tables)** | Associated to Spoke Subnets | Route `0.0.0.0/0` to `10.0.3.4` | Overrides default Azure internet bypass; forces all traffic through firewall inspection. |
| **NSGs** | On every subnet | Microsegmentation | Layer 4 port filtering between tiers (Web cannot reach DB directly). |
| **Decoupled IaC Layers**| In `/layers` directory | In CI/CD pipelines and deployment | Minimizes blast radius; protects central connectivity state from spoke changes. |
