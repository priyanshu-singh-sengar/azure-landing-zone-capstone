terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  # Default local backend for offline verification and sandboxed testing.
  # For production, uncomment and configure the Azure Blob Storage backend below:
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state-mgmt"
  #   storage_account_name = "sttfstatemgmt001"
  #   container_name       = "tfstate"
  #   key                  = "governance.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {}
}
