variable "management_group_id" {
  type        = string
  description = "The ID of the Management Group to assign policies to."
}

variable "allowed_locations" {
  type        = list(string)
  description = "List of approved Azure regions for deployments."
  default     = ["eastus", "eastus2", "centralus"]
}

variable "enable_deny_public_ip" {
  type        = bool
  description = "Whether to enforce denying public IPs on network interfaces."
  default     = true
}

variable "mandatory_tag_name" {
  type        = string
  description = "The mandatory tag name to enforce (e.g. Environment, IaC_Managed)."
  default     = "Environment"
}
