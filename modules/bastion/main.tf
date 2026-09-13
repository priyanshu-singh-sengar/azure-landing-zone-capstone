terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tunneling_enabled   = var.sku == "Standard" ? var.tunneling_enabled : null
  file_copy_enabled   = var.sku == "Standard" ? var.file_copy_enabled : null

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = merge(
    {
      IaC_Managed = "Terraform"
    },
    var.tags
  )
}
