terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location

  tags = merge(
    {
      IaC_Managed = "Terraform"
      CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [
      tags["CreatedAt"]
    ]
  }
}
