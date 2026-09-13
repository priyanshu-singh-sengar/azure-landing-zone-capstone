variable "name" {
  type        = string
  description = "Name of the Network Security Group."
}

variable "location" {
  type        = string
  description = "Azure region where the NSG will be deployed."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "security_rules" {
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  description = "List of security rules to apply to the Network Security Group."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the NSG."
  default     = {}
}
