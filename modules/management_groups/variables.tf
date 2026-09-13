variable "alz_root_id" {
  type        = string
  description = "Unique identifier for the top-level ALZ Root Management Group."
  default     = "alz-enterprise"
}

variable "alz_root_name" {
  type        = string
  description = "Display name for the top-level ALZ Root Management Group."
  default     = "Enterprise ALZ Root"
}

variable "parent_management_group_id" {
  type        = string
  description = "The ID of the parent Management Group. Defaults to null (placed under Tenant Root Group)."
  default     = null
}
