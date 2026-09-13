variable "name" {
  type        = string
  description = "The name of the Virtual Network."
}

variable "location" {
  type        = string
  description = "The Azure region for the Virtual Network."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "address_space" {
  type        = list(string)
  description = "The CIDR address spaces of the Virtual Network."
}

variable "dns_servers" {
  type        = list(string)
  description = "List of IP addresses of DNS servers. Defaults to Azure default DNS if null."
  default     = null
}

variable "subnets" {
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string))
    private_endpoint_network_policies_enabled     = optional(bool, true)
    private_link_service_network_policies_enabled = optional(bool, true)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    }))
  }))
  description = "Map of subnets to create within the Virtual Network."
  default     = {}
}

variable "subnet_nsg_ids" {
  type        = map(string)
  description = "Map of subnet name to Network Security Group ID."
  default     = {}
}

variable "subnet_route_table_ids" {
  type        = map(string)
  description = "Map of subnet name to Route Table ID."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the virtual network."
  default     = {}
}
