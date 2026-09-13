variable "name" {
  type        = string
  description = "The name of the Azure Firewall."
}

variable "location" {
  type        = string
  description = "The Azure region for the Firewall."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "firewall_subnet_id" {
  type        = string
  description = "The resource ID of the AzureFirewallSubnet."
}

variable "firewall_management_subnet_id" {
  type        = string
  description = "The resource ID of the AzureFirewallManagementSubnet (required if sku_tier is Basic)."
  default     = null
}

variable "sku_tier" {
  type        = string
  description = "The SKU tier of the Firewall: Basic, Standard, or Premium."
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of: Basic, Standard, Premium."
  }
}

variable "enable_dns_proxy" {
  type        = bool
  description = "Enable DNS proxy on the Azure Firewall Policy."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Azure Firewall resources."
  default     = {}
}
