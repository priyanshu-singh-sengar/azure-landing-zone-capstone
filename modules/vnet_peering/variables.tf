variable "vnet_1_name" {
  type        = string
  description = "Name of the first Virtual Network (typically Hub)."
}

variable "vnet_1_id" {
  type        = string
  description = "Resource ID of the first Virtual Network (typically Hub)."
}

variable "vnet_1_rg" {
  type        = string
  description = "Resource group name of the first Virtual Network."
}

variable "vnet_2_name" {
  type        = string
  description = "Name of the second Virtual Network (typically Spoke)."
}

variable "vnet_2_id" {
  type        = string
  description = "Resource ID of the second Virtual Network (typically Spoke)."
}

variable "vnet_2_rg" {
  type        = string
  description = "Resource group name of the second Virtual Network."
}

variable "peering_name_1_to_2" {
  type        = string
  description = "Custom peering name from VNet 1 to VNet 2."
  default     = null
}

variable "peering_name_2_to_1" {
  type        = string
  description = "Custom peering name from VNet 2 to VNet 1."
  default     = null
}

variable "allow_virtual_network_access" {
  type        = bool
  description = "Controls if traffic from the peered VNet is allowed into the local VNet."
  default     = true
}

variable "allow_forwarded_traffic" {
  type        = bool
  description = "Controls if forwarded traffic from VMs in the remote VNet is allowed."
  default     = true
}

variable "allow_gateway_transit" {
  type        = bool
  description = "Controls if gateway transit is permitted from VNet 1 to VNet 2."
  default     = false
}

variable "use_remote_gateways" {
  type        = bool
  description = "Controls if VNet 2 uses the remote gateway in VNet 1 (requires an existing Gateway in VNet 1)."
  default     = false
}
