variable "name" {
  type        = string
  description = "The name of the Virtual Network Gateway."
}

variable "location" {
  type        = string
  description = "The Azure region for the Gateway."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "gateway_subnet_id" {
  type        = string
  description = "The ID of the GatewaySubnet (must be named GatewaySubnet)."
}

variable "type" {
  type        = string
  description = "The type of Virtual Network Gateway: 'Vpn' or 'ExpressRoute'."
  default     = "Vpn"
}

variable "vpn_type" {
  type        = string
  description = "The routing type of the VPN Gateway: 'RouteBased' or 'PolicyBased'."
  default     = "RouteBased"
}

variable "sku" {
  type        = string
  description = "Configuration of the size and capacity of the gateway, e.g. VpnGw1, VpnGw2, Basic."
  default     = "VpnGw1"
}

variable "enable_bgp" {
  type        = bool
  description = "If true, BGP (Border Gateway Protocol) is enabled for this Virtual Network Gateway."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Gateway resources."
  default     = {}
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the public IP and zone-redundant gateway."
  default     = ["1", "2", "3"]
}
