# layers/02-spokes/

## Purpose

This is the third and final deployment layer. It creates per-environment workload networks (dev, test, prod). Each spoke is an independent, isolated VNet that connects back to the Hub through VNet peering and has all its egress traffic forced through the Hub Firewall via a User-Defined Route. The same Terraform code is applied three times with different variable files — one per environment.

---

## Files

### main.tf

Contains six logical sections:

**1. `module "spoke_rg"`**

Creates the spoke resource group. The name comes from `var.resource_group_name`, which is set per environment in the `.tfvars` file (e.g., `rg-dev-workloads-01`).

**2. Three NSG modules: `web_nsg`, `app_nsg`, `db_nsg`**

Implements three-tier microsegmentation. Each NSG is associated with one subnet tier.

**`web_nsg`** (applied to `snet-web`):
- Allow inbound HTTP (80) from any source
- Allow inbound HTTPS (443) from any source
- Deny inbound traffic from the database subnet CIDR (priority 300)

The web tier is the public-facing entry point. The explicit deny of db CIDR traffic prevents any database-initiated lateral movement to web servers.

**`app_nsg`** (applied to `snet-app`):
- Allow inbound ports 8080/8443/5000 only from `var.web_subnet_cidr`
- Allow inbound SSH (22) and RDP (3389) from `10.0.2.0/26` (the Hub AzureBastionSubnet)
- Deny all inbound from Internet (priority 400)

The app tier enforces strict source restriction. Application servers should only receive traffic from web servers. SSH/RDP is only allowed from Bastion's known subnet CIDR, not from any arbitrary source.

**`db_nsg`** (applied to `snet-db`):
- Allow inbound SQL ports (1433 MS SQL, 5432 PostgreSQL, 3306 MySQL) only from `var.app_subnet_cidr`
- Deny inbound from `var.web_subnet_cidr` (priority 200)
- Deny inbound from Internet (priority 400)

The database tier only accepts traffic from the application tier. The explicit deny of web CIDR traffic prevents an attacker who compromised a web server from directly connecting to databases.

**3. `module "spoke_route_table"`**

Creates a route table with a single rule:
```
Name:          udr-default-to-hub-firewall
Prefix:        0.0.0.0/0
Next hop type: VirtualAppliance
Next hop IP:   var.hub_firewall_private_ip
```

This is the forced tunnelling route. All internet-bound traffic from any spoke subnet is redirected to the Azure Firewall in the hub for inspection. The firewall then allows or denies traffic based on its rule collection.

**4. `module "spoke_vnet"`**

Creates the spoke VNet with four subnets:
- `snet-web`: Web tier
- `snet-app`: Application tier
- `snet-db`: Database tier
- `snet-pe`: Private Endpoints (no NSG or route table — private endpoint network policies are managed differently)

The module call maps NSGs and route tables to subnets via the `subnet_nsg_ids` and `subnet_route_table_ids` maps. Note that `snet-pe` has no NSG or UDR — private endpoint subnets need to handle traffic differently.

**5. `module "peering"` (conditional)**

Creates bi-directional VNet peering between Hub and Spoke:
- Hub → Spoke peering: `allow_gateway_transit = true` (hub shares its VPN Gateway)
- Spoke → Hub peering: `use_remote_gateways = var.use_remote_gateways` (spoke uses hub gateway)

The `count = var.enable_peering ? 1 : 0` flag allows standalone spoke testing without requiring the hub to exist.

**6. Optional test VM (conditional)**

When `enable_test_vm = true`, creates:
- A Network Interface in `snet-app` with a dynamic private IP and no public IP
- A Linux VM (Ubuntu 22.04 LTS) in `snet-app`

This VM is used to validate that routing and firewall rules work correctly. Because it has no public IP and is in `snet-app`, the only way to reach it is through Azure Bastion.

---

### variables.tf

Key variables that differ per environment:

| Variable | Purpose |
|---|---|
| `environment` | Environment name (dev/test/prod), used in resource naming |
| `resource_group_name` | Spoke resource group name |
| `vnet_address_space` | Spoke VNet CIDR (10.1.0.0/16 for dev, etc.) |
| `web_subnet_cidr` | Web tier CIDR |
| `app_subnet_cidr` | App tier CIDR |
| `data_subnet_cidr` | Database tier CIDR |
| `pe_subnet_cidr` | Private endpoints subnet CIDR |
| `hub_vnet_id` | Hub VNet ID (from Hub layer outputs) |
| `hub_vnet_name` | Hub VNet name (from Hub layer outputs) |
| `hub_resource_group_name` | Hub resource group (from Hub layer outputs) |
| `hub_firewall_private_ip` | Firewall private IP (from Hub layer outputs, used in UDR) |
| `enable_peering` | Whether to peer with hub |
| `use_remote_gateways` | Whether to use hub VPN Gateway |
| `enable_test_vm` | Whether to deploy a validation VM |

---

### environments/

Contains one `.tfvars` file per environment:
- `dev.tfvars`: Dev spoke configuration
- `test.tfvars`: Test spoke configuration
- `prod.tfvars`: Prod spoke configuration

The CI/CD pipeline selects the correct file using the matrix variable: `-var-file="environments/${{ matrix.env }}.tfvars"`.

---

### backend.tf

Remote state configuration:
- Container key: `spokes.tfstate`

All three environment deployments share the same state file. This is intentional: the state tracks all three environments' resources under one root module, differentiated by resource naming conventions.

---

## Deployment

```bash
cd layers/02-spokes

# Deploy dev spoke
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy test spoke
terraform plan -var-file="environments/test.tfvars"
terraform apply -var-file="environments/test.tfvars"

# Deploy prod spoke
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

This layer must be deployed after Layer 01 (hub) because it requires the hub VNet ID, hub VNet name, hub resource group name, and firewall private IP as inputs.
