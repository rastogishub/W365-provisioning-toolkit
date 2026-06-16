# =============================================================
# Windows 365 Cloud PC Toolkit - Outputs
# =============================================================

output "w365_vnet_id" {
  description = "Resource ID of the W365 virtual network"
  value       = azurerm_virtual_network.w365.id
}

output "w365_subnet_id" {
  description = "Subnet ID to reference in the Azure Network Connection (ANC)"
  value       = azurerm_subnet.w365_cloudpc.id
}

output "w365_resource_group_name" {
  description = "Resource group for W365 resources"
  value       = azurerm_resource_group.w365.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for W365 diagnostics"
  value       = azurerm_log_analytics_workspace.w365.id
}

output "keyvault_uri" {
  description = "URI of the W365 Key Vault"
  value       = azurerm_key_vault.w365.vault_uri
}

output "standard_user_group_object_id" {
  description = "Object ID of Standard Cloud PC user group"
  value       = data.azuread_group.w365_standard_users.object_id
}

output "frontline_user_group_object_id" {
  description = "Object ID of Frontline Cloud PC user group"
  value       = data.azuread_group.w365_frontline_users.object_id
}
