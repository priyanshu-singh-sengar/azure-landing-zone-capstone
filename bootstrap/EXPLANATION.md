# Bootstrap Layer — Detailed Code & Architecture Explanation

## 1. Overview & Purpose

The `bootstrap/` folder solves the **chicken-and-egg problem** of Terraform remote state storage:
- To store Terraform state safely and centrally in Azure Blob Storage with automated locking, the Azure Storage Account and Blob Container must already exist.
- However, you cannot use Terraform with a remote Azure backend to create the very storage account that will host that remote backend.

The bootstrap layer breaks this circular dependency. It is executed **once** from an administrator workstation with local state to provision the remote state storage infrastructure. Once created, all subsequent layers (`00-governance`, `01-connectivity-hub`, `02-spokes`) point their `backend.tf` configurations to this storage account and never look back.

---

## 2. When, Where, and Why

| Aspect | Description |
|---|---|
| **Where** | Deployed into the primary subscription in a dedicated resource group: `rg-terraform-state` in Azure region `eastus`. |
| **When** | Day 0 initialization. Must be run before any other Terraform layer is initialized or planned. |
| **Why** | Guarantees central state durability, team concurrency control via state locking leases, auditability, and protection against accidental deletion or state corruption. |

---

## 3. Code Walkthrough: File by File

### `main.tf`

The `main.tf` file contains the complete definition for the bootstrap resources:

#### 1. Terraform & Provider Block (Lines 1–17)
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}
```
- **`required_version = ">= 1.5.0"`**: Enforces modern Terraform syntax and features (such as `check` blocks and refined import blocks).
- **`azurerm ~> 3.110`**: Uses HashiCorp's official Azure Resource Manager provider with minor version pinning to avoid breaking changes.
- **`random ~> 3.5`**: Used to generate a unique random string suffix for the globally unique storage account name.
- **`features {}`**: Required configuration block for the `azurerm` provider.

#### 2. Input Variables (Lines 19–23)
```hcl
variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region for the Terraform remote state storage."
}
```
- Defines the target Azure datacenter. Defaulted to `eastus` to keep state geographically close to primary workload deployments, minimizing network latency during CI/CD plan and apply cycles.

#### 3. Random Suffix Resource (Lines 25–29)
```hcl
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
```
- Azure Storage Account names must be globally unique across all of Azure, between 3 and 24 characters, and alphanumeric lowercase only.
- Setting `special = false` and `upper = false` ensures strict compliance with Azure storage naming constraints.

#### 4. Resource Group (`azurerm_resource_group.tfstate`, Lines 31–41)
```hcl
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-terraform-state"
  location = var.location

  tags = {
    Environment = "Management"
    Project     = "Azure-Landing-Zone"
    IaC_Managed = "Terraform"
    Purpose     = "Terraform Remote State Storage"
  }
}
```
- Creates an isolated container (`rg-terraform-state`) holding exclusively state storage resources.
- Explicit tagging ensures compliance with governance policies and FinOps cost tracking.

#### 5. Storage Account (`azurerm_storage_account.tfstate`, Lines 43–59)
```hcl
resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
  }

  tags = azurerm_resource_group.tfstate.tags
}
```
- **`account_tier = "Standard"`**: Storage state files are lightweight JSON documents; Standard tier provides cost-effective throughput.
- **`account_replication_type = "GRS"`**: Geo-Redundant Storage replicates state data asynchronously to a secondary paired region (e.g., `westus`), protecting against regional disaster.
- **`min_tls_version = "TLS1_2"`**: Enforces encrypted transport in transit; rejects obsolete TLS 1.0/1.1 protocols.
- **`versioning_enabled = true`**: Critical state protection. Every `terraform apply` writes a new state snapshot. If state is corrupted, previous versions can be restored instantly from blob history.
- **`delete_retention_policy { days = 30 }`**: Soft delete keeps deleted state files recoverable for 30 days against accidental deletion.

#### 6. Blob Container (`azurerm_storage_container.tfstate`, Lines 61–65)
```hcl
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
```
- Creates the `tfstate` container.
- **`container_access_type = "private"`**: Disables anonymous public read access. Access is strictly gated by Microsoft Entra ID (OIDC) or storage account keys.

#### 7. Outputs (Lines 67–80)
```hcl
output "resource_group_name" {
  value       = azurerm_resource_group.tfstate.name
  description = "The resource group containing the remote state storage account."
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "The storage account name to configure in backend.tf."
}

output "container_name" {
  value       = azurerm_storage_container.tfstate.name
  description = "The container name for Terraform remote state."
}
```
- Exposes values needed by developers and CI/CD pipelines to populate the `backend.tf` configuration of downstream layers.

---

## 4. How Downstream Layers Consume Bootstrap Outputs

Once applied, the storage account name emitted by `output "storage_account_name"` is plugged into the `backend.tf` files across all layers:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "<OUTPUT_STORAGE_ACCOUNT_NAME>"
    container_name       = "tfstate"
    key                  = "01-connectivity-hub.tfstate"
  }
}
```

Each layer uses a distinct `key` inside the same container, guaranteeing state separation and independent state locks.
