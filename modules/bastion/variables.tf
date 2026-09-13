variable "name" {
  type        = string
  description = "The name of the Azure Bastion Host."
}

variable "location" {
  type        = string
  description = "The Azure region for the Bastion Host."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name."
}

variable "bastion_subnet_id" {
  type        = string
  description = "The ID of the AzureBastionSubnet (must be at least /26)."
}

variable "sku" {
  type        = string
  description = "The SKU of the Bastion Host: Basic or Standard."
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be either 'Basic' or 'Standard'."
  }
}

variable "tunneling_enabled" {
  type        = bool
  description = "Enable native client tunneling (Standard SKU only)."
  default     = true
}

variable "file_copy_enabled" {
  type        = bool
  description = "Enable file copy over Bastion (Standard SKU only)."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Bastion resources."
  default     = {}
}
