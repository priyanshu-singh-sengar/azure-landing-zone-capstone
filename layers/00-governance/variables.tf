variable "alz_root_id" {
  type        = string
  description = "Identifier for the top-level ALZ Root Management Group."
  default     = "alz-enterprise"
}

variable "alz_root_name" {
  type        = string
  description = "Display name for the top-level ALZ Root Management Group."
  default     = "Enterprise ALZ Root"
}

variable "parent_management_group_id" {
  type        = string
  description = "Parent Management Group ID (null defaults to Tenant Root Group)."
  default     = null
}

variable "allowed_locations" {
  type        = list(string)
  description = "Allowed Azure regions for deployment."
  default     = ["eastus", "eastus2", "centralus"]
}

variable "enable_deny_public_ip" {
  type        = bool
  description = "Deny public IPs on workload network interfaces."
  default     = true
}

variable "mandatory_tag_name" {
  type        = string
  description = "Name of the mandatory tag enforced on resources."
  default     = "Environment"
}
