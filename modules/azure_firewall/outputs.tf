output "id" {
  value       = azurerm_firewall.fw.id
  description = "The ID of the Azure Firewall."
}

output "name" {
  value       = azurerm_firewall.fw.name
  description = "The name of the Azure Firewall."
}

output "private_ip_address" {
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  description = "The private IP address of the Azure Firewall (used as next hop in UDRs, typically 10.0.3.4)."
}

output "public_ip_address" {
  value       = azurerm_public_ip.fw_pip.ip_address
  description = "The public IP address of the Azure Firewall."
}

output "policy_id" {
  value       = azurerm_firewall_policy.fw_policy.id
  description = "The ID of the Azure Firewall Policy."
}
