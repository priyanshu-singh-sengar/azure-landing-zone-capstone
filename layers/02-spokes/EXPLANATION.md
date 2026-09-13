# Spokes Layer (`layers/02-spokes`) — Detailed Explanation

## 1. Overview & Purpose

The `layers/02-spokes` layer provisions **isolated application workload networks** (`dev`, `test`, `prod`). Each spoke is an independent Virtual Network connected back to the Hub VNet via high-speed VNet Peering.

Workload spokes enforce two fundamental security principles:
1. **Defense-in-Depth Microsegmentation:** 3-tier subnet architecture (`snet-web`, `snet-app`, `snet-db`) with dedicated NSGs preventing web servers from directly communicating with backend databases.
2. **Forced Tunneling via UDR:** Route tables attached to subnets override Azure's default Internet route, forcing `0.0.0.0/0` outbound traffic through the central Azure Firewall (`10.0.3.4`).

---

## 2. When, Where, and Why

| Aspect | Detail |
|---|---|
| **Where** | Deployed into respective workload subscriptions (`sub-workloads-dev`, `sub-workloads-prod`) using non-overlapping IP address spaces (`10.1.0.0/16`, `10.2.0.0/16`, `10.3.0.0/16`). |
| **When** | Deployed after the Hub network is fully operational. |
| **Why** | Guarantees workload isolation. Dev bugs or compromised containers cannot reach production databases because spokes are never directly peered to one another. |

---

## 3. Subnet Layout & Address Allocation

```text
Spoke VNet (e.g., DEV: 10.1.0.0/16 | TEST: 10.2.0.0/16 | PROD: 10.3.0.0/16)
 ├── snet-web (10.x.1.0/24)  --> Public/Internal Ingress, Reverse Proxies (NSG: nsg-<env>-web)
 ├── snet-app (10.x.2.0/24)  --> APIs, Microservices, Compute (NSG: nsg-<env>-app)
 ├── snet-db  (10.x.3.0/24)  --> Databases, Private Storage (NSG: nsg-<env>-db)
 └── snet-pe  (10.x.4.0/24)  --> Private Endpoints (SQL, KeyVault, Storage)
```

---

## 4. Code Walkthrough: File by File

### `backend.tf`
- Stores remote state under `spokes-<environment>.tfstate` in `rg-terraform-state`.
- Authenticates via OIDC (`use_azuread_auth = true`).

---

### `variables.tf`
- **`environment`**: Target tier (`"dev"`, `"test"`, `"prod"`).
- **`vnet_address_space`**: Address prefix for the spoke (`10.1.0.0/16` for dev, `10.3.0.0/16` for prod).
- **Subnet CIDRs**: `web_subnet_cidr`, `app_subnet_cidr`, `data_subnet_cidr`, `pe_subnet_cidr`.
- **Hub Inputs**:
  - `hub_vnet_name`, `hub_vnet_id`, `hub_resource_group_name`: For peering creation.
  - `hub_firewall_private_ip` (`default = "10.0.3.4"`): Used as next hop in UDR.
  - `use_remote_gateways`: Boolean toggle allowing spokes to utilize the Hub VPN Gateway.
- **`enable_test_vm`** (`bool`, default `false`): Deploys a minimal Ubuntu VM in `snet-app` to validate end-to-end Bastion SSH connectivity and forced tunneling egress.

---

### `main.tf`

#### 1. Spoke Resource Group (`module.spoke_rg`, Lines 1–8)
- Creates `rg-spoke-<env>-01` to house the VNet and spoke resources.

#### 2. Tier NSGs & Microsegmentation (Lines 10–156)
- **Web NSG (`module.web_nsg`)**:
  - Allows HTTP (`80`) and HTTPS (`443`) from perimeter or reverse proxy.
  - Denies traffic originating from the Database tier (`DenyDataDirectAccess`).
- **App NSG (`module.app_nsg`)**:
  - **`AllowInboundFromWeb`**: Only accepts traffic on application ports (`8080`, `8443`, `5000`) strictly from the `snet-web` CIDR.
  - **`AllowBastionSshRdpInbound`**: Accepts SSH (`22`) and RDP (`3389`) strictly from the Hub's `AzureBastionSubnet` (`10.0.2.0/26`).
  - **`DenyDirectInternetInbound`**: Drops any packet from the public Internet attempting direct app ingress.
- **Database NSG (`module.db_nsg`)**:
  - **`AllowInboundFromApp`**: Only accepts database ports (`1433`, `5432`, `3306`) strictly from `snet-app`.
  - **`DenyDirectWebInbound`**: Explicitly blocks traffic from `snet-web` that attempts to bypass the application tier.
  - **`DenyDirectInternetInbound`**: Blocks all Internet traffic.

#### 3. Forced Tunneling Route Table (`module.spoke_route_table`, Lines 158–176)
```hcl
routes = [
  {
    name                   = "udr-default-to-hub-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }
]
```
- Attaching this route table overrides Azure's default routing. All outbound traffic from spoke VMs must pass through `10.0.3.4` (Azure Firewall) for deep packet inspection and DNS filtering.

#### 4. Spoke Virtual Network (`module.spoke_vnet`, Lines 178–215)
- Creates the VNet and associates:
  - `snet-web` -> `module.web_nsg.id` & `module.spoke_route_table.id`
  - `snet-app` -> `module.app_nsg.id` & `module.spoke_route_table.id`
  - `snet-db`  -> `module.db_nsg.id`  & `module.spoke_route_table.id`

#### 5. Bi-Directional VNet Peering (`module.peering`, Lines 217–234)
- Establishes two peering links (`Hub -> Spoke` and `Spoke -> Hub`) with:
  - `allow_virtual_network_access = true`
  - `allow_forwarded_traffic = true`
  - `use_remote_gateways = var.use_remote_gateways`

#### 6. Optional Validation Test VM (Lines 236–280)
- Provisions an Ubuntu 22.04 VM strictly within `snet-app`.
- **Zero Public IP**: The network interface has only a private IP (`Dynamic`). The VM is completely unreachable from the public internet and complies with the Landing Zone `Deny Public IP` policy.
- Access is gained exclusively via Azure Bastion tunneling (`az network bastion ssh`).

---

### `outputs.tf`
Emits:
- `spoke_vnet_id`, `spoke_vnet_name`
- `web_subnet_id`, `app_subnet_id`, `db_subnet_id`, `pe_subnet_id`
- `route_table_id`
- `test_vm_id`, `test_vm_private_ip` (when enabled)
