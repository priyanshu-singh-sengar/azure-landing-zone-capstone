# layers/01-connectivity-hub/

## Purpose

This is the second deployment layer. It provisions all shared networking infrastructure into a single resource group (`rg-hub-prod-01`). The hub is the central connectivity point for all workload spokes. It hosts the firewall (all egress inspection), Bastion (secure VM access), and the VPN Gateway (on-premises connectivity). Once deployed, this layer is rarely modified — it is the stable foundation that spoke layers depend on.

---

## Files

### main.tf

Contains six module calls in logical dependency order:

**1. `module "hub_rg"`**

Creates `rg-hub-prod-01` using `modules/resource_group`. All hub resources are placed in this resource group.

**2. `module "bastion_nsg"`**

Creates the NSG required by Azure Bastion before the VNet exists, because the VNet module needs the NSG ID for subnet association.

Azure Bastion has mandatory NSG rules specified by Microsoft. If these rules are absent, Bastion stops functioning. The rules allow:
- Inbound HTTPS (443) from Internet: user browser connections
- Inbound HTTPS (443) from GatewayManager: Azure control plane
- Inbound HTTPS (443) from AzureLoadBalancer: health probes
- Inbound ports 8080/5701 from VirtualNetwork: inter-node Bastion communication
- Outbound SSH (22) and RDP (3389) to VirtualNetwork: connections to target VMs
- Outbound HTTPS (443) to AzureCloud: management plane
- Outbound ports 8080/5701 to VirtualNetwork: inter-node communication
- Outbound port 80 to Internet: session information lookup

**3. `module "shared_svc_nsg"`**

Creates the NSG for the shared services subnet. Rules:
- Allow all inbound from VirtualNetwork (internal services can communicate)
- Deny all inbound from Internet at priority 4096 (explicit block)

**4. `module "hub_vnet"`**

Creates the Hub VNet (`vnet-hub-prod-01`, `10.0.0.0/16`) with five dedicated subnets:
- `GatewaySubnet` (10.0.1.0/24): Azure requirement — VPN Gateway must be in a subnet named exactly `GatewaySubnet`.
- `AzureBastionSubnet` (10.0.2.0/26): Azure requirement — Bastion must be in a subnet named exactly `AzureBastionSubnet`. /26 is the minimum size.
- `AzureFirewallSubnet` (10.0.3.0/26): Azure requirement — Firewall must be in `AzureFirewallSubnet`. /26 minimum.
- `AzureFirewallManagementSubnet` (10.0.3.128/26): Required for Basic SKU Firewall; provisioned here for flexibility.
- `snet-shared-svc` (10.0.4.0/24): General-purpose subnet for DNS servers, monitoring agents, etc.

The `subnet_nsg_ids` map associates the Bastion and shared-svc NSGs with their respective subnets. The VNet module handles the `azurerm_subnet_network_security_group_association` resources internally.

**5. `module "azure_firewall"`**

Creates the Azure Firewall with:
- Standard SKU
- A static public IP (`afw-hub-prod-01-pip`)
- A Firewall Policy with DNS proxy enabled
- Default egress rules (DNS, NTP, FQDN-based web egress)

The `enable_dns_proxy = true` setting is critical: it allows the Firewall to act as a DNS forwarder for VMs in peered spoke VNets. Without DNS proxy, FQDN-based network rules in the firewall policy do not resolve correctly.

**6. `module "bastion"`**

Creates Azure Bastion with:
- Standard SKU (supports native client tunnelling, not just browser)
- `tunneling_enabled = true`: Allows native SSH/RDP clients to connect through Bastion instead of the portal-only browser experience

**7. `module "vpn_gateway"` (conditional)**

Created only when `enable_vpn_gateway = true`. Uses `VpnGw1AZ` SKU (zone-redundant, meaning the gateway is distributed across availability zones and survives a zone failure). Type is `Vpn`, VPN type is `RouteBased` (required for most modern VPN devices and always used for new deployments). BGP is disabled (static routing).

---

### variables.tf

Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `location` | `eastus` | Azure region for all hub resources |
| `resource_group_name` | `rg-hub-prod-01` | Hub resource group name |
| `vnet_address_space` | `["10.0.0.0/16"]` | Hub VNet CIDR |
| `firewall_sku_tier` | `Standard` | Firewall tier |
| `bastion_sku` | `Standard` | Bastion tier |
| `enable_vpn_gateway` | `true` | Toggle VPN Gateway deployment |
| `vpn_gateway_sku` | `VpnGw1AZ` | VPN Gateway SKU (zone-redundant) |
| `tags` | Map | Standard tags applied to all hub resources |

---

### outputs.tf

Exposes values consumed by Layer 02:
- `hub_vnet_id`: Required by spoke peering configuration
- `hub_vnet_name`: Required by spoke peering configuration
- `hub_resource_group_name`: Required by spoke peering configuration
- `hub_firewall_private_ip`: Required by spoke UDR (route table next hop)

---

### backend.tf

Remote state configuration:
- Container key: `hub.tfstate`
- `use_azuread_auth = true`: No storage key used

---

### environments/

Contains `hub.tfvars` — the variable values used when deploying. This file is referenced in CI/CD commands as `-var-file="environments/hub.tfvars"`.

---

## Deployment

```bash
cd layers/01-connectivity-hub
terraform init
terraform plan -var-file="environments/hub.tfvars"
terraform apply -var-file="environments/hub.tfvars"
```

This layer must be deployed after Layer 00 (governance) and before Layer 02 (spokes). The VPN Gateway takes 20–45 minutes to provision.
