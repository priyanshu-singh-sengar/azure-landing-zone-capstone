variable "location" {
  type        = string
  description = "The Azure region for the Hub infrastructure."
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Hub Resource Group."
  default     = "rg-hub-prod-01"
}

variable "vnet_name" {
  type        = string
  description = "The name of the Hub Virtual Network."
  default     = "vnet-hub-prod-01"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Hub VNet."
  default     = ["10.0.0.0/16"]
}

variable "gateway_subnet_cidr" {
  type        = string
  description = "CIDR prefix for GatewaySubnet."
  default     = "10.0.1.0/24"
}

variable "bastion_subnet_cidr" {
  type        = string
  description = "CIDR prefix for AzureBastionSubnet."
  default     = "10.0.2.0/26"
}

variable "firewall_subnet_cidr" {
  type        = string
  description = "CIDR prefix for AzureFirewallSubnet."
  default     = "10.0.3.0/26"
}

variable "firewall_mgmt_subnet_cidr" {
  type        = string
  description = "CIDR prefix for AzureFirewallManagementSubnet."
  default     = "10.0.3.128/26"
}

variable "shared_svc_subnet_cidr" {
  type        = string
  description = "CIDR prefix for shared services subnet."
  default     = "10.0.4.0/24"
}

variable "firewall_name" {
  type        = string
  description = "Name of the Azure Firewall."
  default     = "afw-hub-prod-01"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU Tier: Basic, Standard, or Premium."
  default     = "Standard"
}

variable "bastion_name" {
  type        = string
  description = "Name of the Azure Bastion host."
  default     = "bas-hub-prod-01"
}

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU: Basic or Standard."
  default     = "Standard"
}

variable "enable_vpn_gateway" {
  type        = bool
  description = "Toggle deployment of VPN Gateway to save cost in test environments."
  default     = true
}

variable "vpn_gateway_name" {
  type        = string
  description = "Name of the VPN Gateway."
  default     = "vpngw-hub-prod-01"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "SKU of the Virtual Network Gateway."
  default     = "VpnGw1AZ"
}

variable "tags" {
  type        = map(string)
  description = "Standard tags for Hub resources."
  default = {
    Environment = "Hub-Platform"
    CostCenter  = "Core-Network-001"
    Owner       = "Cloud-Platform-Team"
    Project     = "Enterprise-ALZ"
  }
}
