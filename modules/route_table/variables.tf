variable "name" {
  type        = string
  description = "The name of the Route Table."
}

variable "location" {
  type        = string
  description = "The Azure region for the Route Table."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group name."
}

variable "disable_bgp_route_propagation" {
  type        = bool
  description = "Whether to disable BGP route propagation on this route table."
  default     = false
}

variable "routes" {
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string # VirtualAppliance, Internet, None, VirtualNetworkGateway, VnetLocal
    next_hop_in_ip_address = optional(string)
  }))
  description = "List of user-defined routes."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Route Table."
  default     = {}
}
