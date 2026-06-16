# =============================================================
# Windows 365 Cloud PC Provisioning Toolkit
# Author : Shubham Rastogi
# Based on 45,000+ W365 Cloud PC deployments at J&J / Avantor
# =============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ------------------------------------------------------------------
# Resource Group
# ------------------------------------------------------------------
resource "azurerm_resource_group" "w365" {
  name     = "rg-w365-${var.environment}-${var.location_short}"
  location = var.location
  tags     = local.common_tags
}

# ------------------------------------------------------------------
# Virtual Network for W365 Azure Network Connection (ANC)
# ------------------------------------------------------------------
resource "azurerm_virtual_network" "w365" {
  name                = "vnet-w365-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.w365.name
  location            = var.location
  address_space       = [var.w365_vnet_cidr]
  dns_servers         = var.dns_servers
  tags                = local.common_tags
}

resource "azurerm_subnet" "w365_cloudpc" {
  name                 = "snet-cloudpc"
  resource_group_name  = azurerm_resource_group.w365.name
  virtual_network_name = azurerm_virtual_network.w365.name
  address_prefixes     = [var.cloudpc_subnet_cidr]
}

# ------------------------------------------------------------------
# Network Security Group for Cloud PC subnet
# ------------------------------------------------------------------
resource "azurerm_network_security_group" "w365" {
  name                = "nsg-w365-cloudpc-${var.environment}"
  resource_group_name = azurerm_resource_group.w365.name
  location            = var.location
  tags                = local.common_tags

  # Allow RDP from corporate network only (Intune-managed traffic)
  security_rule {
    name                       = "Allow-RDP-Inbound-Corp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefixes    = var.corporate_ip_ranges
    destination_address_prefix = "*"
  }

  # Allow W365 service endpoints (Microsoft-managed)
  security_rule {
    name                       = "Allow-W365-Service"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "WindowsVirtualDesktop"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "w365" {
  subnet_id                 = azurerm_subnet.w365_cloudpc.id
  network_security_group_id = azurerm_network_security_group.w365.id
}

# ------------------------------------------------------------------
# Hub VNet Peering (connect to corporate hub for on-prem access)
# ------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "w365_to_hub" {
  name                      = "peer-w365-to-hub"
  resource_group_name       = azurerm_resource_group.w365.name
  virtual_network_name      = azurerm_virtual_network.w365.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_w365" {
  name                      = "peer-hub-to-w365"
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.w365.id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
  allow_virtual_network_access = true
}

# ------------------------------------------------------------------
# Azure AD Groups for W365 licensing and provisioning policies
# ------------------------------------------------------------------
data "azuread_group" "w365_standard_users" {
  display_name     = var.w365_standard_group_name
  security_enabled = true
}

data "azuread_group" "w365_frontline_users" {
  display_name     = var.w365_frontline_group_name
  security_enabled = true
}

# ------------------------------------------------------------------
# Log Analytics for Cloud PC diagnostics & monitoring
# ------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "w365" {
  name                = "law-w365-${var.environment}-${var.location_short}"
  resource_group_name = azurerm_resource_group.w365.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# ------------------------------------------------------------------
# Diagnostic Settings on the W365 VNet
# ------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet-w365"
  target_resource_id         = azurerm_virtual_network.w365.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.w365.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ------------------------------------------------------------------
# Key Vault for W365 secrets (join tokens, certs)
# ------------------------------------------------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "w365" {
  name                       = "kv-w365-${var.environment}-${var.location_short}"
  resource_group_name        = azurerm_resource_group.w365.name
  location                   = var.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = local.common_tags
}

# ------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------
locals {
  common_tags = {
    Environment  = var.environment
    Service      = "Windows365-CloudPC"
    ManagedBy    = "Terraform"
    Owner        = var.team_owner
    CostCenter   = var.cost_center
  }
}
