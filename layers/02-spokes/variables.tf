variable "environment" {
  type        = string
  description = "The deployment environment: dev, test, or prod."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region for the Spoke infrastructure."
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Spoke Resource Group."
  default     = "rg-spoke-dev-01"
}

variable "vnet_name" {
  type        = string
  description = "The name of the Spoke Virtual Network."
  default     = "vnet-spoke-dev-01"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Spoke VNet."
  default     = ["10.1.0.0/16"]
}

variable "web_subnet_cidr" {
  type        = string
  description = "CIDR prefix for Web subnet."
  default     = "10.1.1.0/24"
}

variable "app_subnet_cidr" {
  type        = string
  description = "CIDR prefix for Application subnet."
  default     = "10.1.2.0/24"
}

variable "data_subnet_cidr" {
  type        = string
  description = "CIDR prefix for Database subnet."
  default     = "10.1.3.0/24"
}

variable "pe_subnet_cidr" {
  type        = string
  description = "CIDR prefix for Private Endpoints subnet."
  default     = "10.1.4.0/24"
}

variable "hub_vnet_id" {
  type        = string
  description = "Resource ID of the Hub VNet to peer with."
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub-prod-01/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-01"
}

variable "hub_vnet_name" {
  type        = string
  description = "Name of the Hub VNet."
  default     = "vnet-hub-prod-01"
}

variable "hub_resource_group_name" {
  type        = string
  description = "Resource group name of the Hub VNet."
  default     = "rg-hub-prod-01"
}

variable "hub_firewall_private_ip" {
  type        = string
  description = "Private IP address of the Hub Azure Firewall."
  default     = "10.0.3.4"
}

variable "enable_peering" {
  type        = bool
  description = "Whether to create the VNet peering with the Hub VNet."
  default     = true
}

variable "use_remote_gateways" {
  type        = bool
  description = "Whether Spoke VNet uses remote gateways in Hub VNet."
  default     = false
}

variable "enable_test_vm" {
  type        = bool
  description = "Whether to deploy a lightweight test VM in the App subnet for connectivity validation."
  default     = false
}

variable "test_vm_size" {
  type        = string
  description = "Size of the validation VM."
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the validation VM."
  default     = "azureuser"
}

variable "admin_password" {
  type        = string
  description = "Admin password for the validation VM."
  default     = "P@ssw0rd1234!"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Spoke resources."
  default = {
    Environment = "DEV"
    CostCenter  = "Dev-Engineering-001"
    Owner       = "Workload-Team"
    Project     = "Enterprise-ALZ"
  }
}
