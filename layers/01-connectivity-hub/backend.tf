terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatew4gika"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}
