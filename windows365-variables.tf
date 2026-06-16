# =============================================================
# Windows 365 Cloud PC Toolkit - Variables
# =============================================================

variable "subscription_id" {
  description = "Azure subscription ID for W365 deployment"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment: dev | uat | prod"
  type        = string
  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Must be dev, uat, or prod."
  }
}

variable "location" {
  description = "Azure region for W365 resources"
  type        = string
  default     = "eastus"
}

variable "location_short" {
  description = "Short region code used in resource names"
  type        = string
  default     = "eus"
}

variable "cost_center" {
  description = "Cost center code for billing"
  type        = string
}

variable "team_owner" {
  description = "Team responsible for this deployment"
  type        = string
  default     = "EUC-CloudPC-Team"
}

# Networking
variable "w365_vnet_cidr" {
  description = "CIDR for the W365 virtual network"
  type        = string
  default     = "10.10.0.0/16"
}

variable "cloudpc_subnet_cidr" {
  description = "CIDR for the Cloud PC subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "dns_servers" {
  description = "Custom DNS servers (point to domain controllers for AD-joined Cloud PCs)"
  type        = list(string)
  default     = []
}

variable "corporate_ip_ranges" {
  description = "List of corporate IP CIDR ranges allowed RDP inbound"
  type        = list(string)
}

# Hub VNet peering
variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub virtual network"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group containing the hub VNet"
  type        = string
}

# Azure AD Groups
variable "w365_standard_group_name" {
  description = "Azure AD group name for Standard Cloud PC users"
  type        = string
  default     = "GRP-W365-Standard-Users"
}

variable "w365_frontline_group_name" {
  description = "Azure AD group name for Frontline Cloud PC users"
  type        = string
  default     = "GRP-W365-Frontline-Users"
}

# Monitoring
variable "log_retention_days" {
  description = "Log Analytics retention period in days"
  type        = number
  default     = 90
}
