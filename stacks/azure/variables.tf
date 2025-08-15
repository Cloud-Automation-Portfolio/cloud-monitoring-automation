variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "monitoring-lab"
}

variable "vm_name" {
  description = "Azure VM name"
  type        = string
  default     = "cma-azure-vm"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Path to SSH public key"
  type        = string
}
