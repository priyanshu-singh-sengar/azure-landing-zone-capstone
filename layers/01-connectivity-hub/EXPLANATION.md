# Connectivity Hub Layer (`layers/01-connectivity-hub`) — Detailed Explanation

## 1. Overview & Purpose

The `layers/01-connectivity-hub` layer provisions the **central networking and security core** of the Azure Landing Zone. In a hub-and-spoke topology, the Hub network acts as the single gateway for all inbound, outbound, and cross-premises communication.

By centralizing firewall inspection, remote management, and hybrid connectivity in the Hub:
- Expensive security appliances (Azure Firewall, VPN Gateways) are provisioned once and shared across all environments (`dev`, `test`, `prod`), eliminating thousands of dollars in duplicated PaaS costs.
- Enterprise security policies and traffic inspection are enforced in a single location.

---

## 2. When, Where, and Why

| Aspect | Detail |
|---|---|
| **Where** | Deployed into the Connectivity/Platform subscription inside resource group `rg-hub-prod-01`. VNet space: `10.0.0.0/16`. |
| **When** | Deployed immediately after `00-governance` and before any workload spokes (`02-spokes`). |
| **Why** | Spokes require the Hub's VNet ID for peering and the Azure Firewall's private IP (`10.0.3.4`) for default next-hop routing tables. |

---

## 3. Subnet Allocation Plan (`10.0.0.0/16`)

```text
Hub VNet (10.0.0.0/16)
 ├── GatewaySubnet (10.0.1.0/24)                    --> VPN Gateway (S2S IPsec / ExpressRoute)
 ├── AzureBastionSubnet (10.0.2.0/26)               --> Azure Bastion Host (TLS 443 Admin Access)
 ├── AzureFirewallSubnet (10.0.3.0/24)              --> Azure Firewall Data Plane (IP: 10.0.3.4)
 ├── AzureFirewallManagementSubnet (10.0.5.0/24)    --> Azure Firewall Management Plane (Basic SKU)
 └── snet-shared-svc (10.0.4.0/24)                  --> Shared Services (DNS, Runners, Tooling)
```

---

## 4. Code Walkthrough: File by File

### `backend.tf`
- Connects to the remote state storage account (`sttfstatew4gika`) in `rg-terraform-state`.
- State key: `01-connectivity-hub.tfstate`.
- Uses Entra ID (OIDC) authentication (`use_azuread_auth = true`).

---

### `variables.tf`
Key variables governing hub behavior:
- **`vnet_address_space`** (`["10.0.0.0/16"]`): The CIDR block for the Hub.
- **Subnet CIDRs**:
  - `gateway_subnet_cidr = "10.0.1.0/24"` (Strictly named `GatewaySubnet`).
  - `bastion_subnet_cidr = "10.0.2.0/26"` (Strictly named `AzureBastionSubnet`, minimum `/26`).
  - `firewall_subnet_cidr = "10.0.3.0/24"` (Strictly named `AzureFirewallSubnet`).
  - `firewall_mgmt_subnet_cidr = "10.0.5.0/24"` (Strictly named `AzureFirewallManagementSubnet`).
  - `shared_svc_subnet_cidr = "10.0.4.0/24"`.
- **`firewall_sku_tier`** (`"Basic"` by default for capstone cost control; supports `"Standard"` or `"Premium"` in enterprise production).
- **`enable_vpn_gateway`** (`bool`, default `false`): Feature toggle to avoid billing for VPN Gateway (~$140/month) when hybrid tunnels are not currently in use.

---

### `main.tf`
Orchestrates 6 core modules in strict dependency order:

#### 1. Hub Resource Group (`module.hub_rg`, Lines 1–8)
- Creates `rg-hub-prod-01` to isolate all hub networking components.

#### 2. Bastion NSG (`module.bastion_nsg`, Lines 10–118)
- Azure Bastion has strict, non-negotiable NSG requirements enforced by Microsoft:
  - **Inbound HTTPS (`443`) from Internet**: Allows admins to connect via web browser.
  - **Inbound `GatewayManager` (`443`)**: Required by Azure management plane.
  - **Inbound `AzureLoadBalancer` (`443`)**: Required for health probes.
  - **Inbound/Outbound `8080`, `5701` within `VirtualNetwork`**: Allows cluster gossip between Bastion scale units.
  - **Outbound `22`, `3389` to `VirtualNetwork`**: Allows Bastion to reach Linux (SSH) and Windows (RDP) VMs across peered spokes.
  - **Outbound `443` to `AzureCloud`**: Accesses Azure management APIs and certificate revocation lists.

#### 3. Shared Services NSG (`module.shared_svc_nsg`, Lines 120–157)
- Allows internal `VirtualNetwork` traffic (priority 200).
- Explicitly blocks direct inbound Internet traffic (`DenyInternetInbound`, priority 4096).

#### 4. Hub Virtual Network (`module.hub_vnet`, Lines 159–192)
- Provisions the VNet and all 5 dedicated subnets.
- Associates `module.bastion_nsg` to `AzureBastionSubnet` and `module.shared_svc_nsg` to `snet-shared-svc`.
- *Note:* Azure rules prohibit attaching an NSG to `AzureFirewallSubnet` or `AzureFirewallManagementSubnet`.

#### 5. Azure Firewall (`module.azure_firewall`, Lines 194–206)
- Deploys the firewall with public IPs and Firewall Policy.
- Enables DNS Proxy so spoke workloads can resolve both private Azure DNS zones and public domain names through the firewall.

#### 6. Azure Bastion Host (`module.bastion`, Lines 208–219)
- Deploys the Bastion host with standard tunneling enabled, allowing native SSH/RDP clients (`az network bastion ssh`) without public VM IPs.

#### 7. Optional VPN Gateway (`module.vpn_gateway`, Lines 221–235)
- Uses `count = var.enable_vpn_gateway ? 1 : 0`.
- Deploys an Active-Active VPN Gateway in `GatewaySubnet` when enabled.

---

### `outputs.tf`
Critical outputs consumed by `02-spokes`:
- **`hub_vnet_id`**: Needed by `02-spokes` to create peering from Spoke to Hub.
- **`hub_vnet_name`**: Human-readable name for logging.
- **`firewall_private_ip`** (`10.0.3.4`): Next-hop IP programmed into Spoke Route Tables (`0.0.0.0/0 -> 10.0.3.4`).
- **`bastion_id`**, **`vpn_gateway_id`**: For status reporting and monitoring integrations.

---

### `environments/prod.tfvars`
Production variable overrides containing production naming prefixes, region specifications, and cost toggles.
