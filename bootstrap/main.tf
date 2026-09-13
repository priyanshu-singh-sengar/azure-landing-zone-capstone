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

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region for the Terraform remote state storage."
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

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

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

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
