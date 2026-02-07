locals {
  public_address_protocol = var.enterprise_config != null ? var.enterprise_config.https_certs != null ? "https" : "http" : null
}

output "agent_configs" {
  value = {
    name = var.name

    subscription_id               = var.subscription_id
    location                      = var.location
    resource_group                = var.resource_group_name
    vnet_name                     = var.vnet_name
    subnet_id                     = var.subnet_id
    security_group_id             = azurerm_network_security_group.agent_nsg.id
    application_security_group_id = azurerm_application_security_group.agent_asg.id
    broker_info = {
      address        = "${azurerm_network_interface.controller_nic.private_ip_address}:50051"
      public_address = var.enterprise_config != null ? "${local.public_address_protocol}://${var.enterprise_config.domain}" : ""
    }
    controller_ip        = azurerm_network_interface.controller_nic.private_ip_address
    managed_identity_id  = local.agent_identity_id
    use_nat              = local.use_nat
    agent_version        = var.controller_version
    app_configuration_id = azurerm_app_configuration.velda_config.id
  }
}

output "postgres_url" {
  description = "PostgreSQL connection URL"
  value       = local.postgres_url
  sensitive   = true
}

output "controller_vm_id" {
  description = "ID of the controller VM"
  value       = azurerm_linux_virtual_machine.controller.id
}

output "controller_public_ip" {
  description = "Public IP address of the controller (if assigned)"
  value       = var.external_access.use_controller_external_ip ? azurerm_public_ip.controller_pip[0].ip_address : null
}

output "controller_private_ip" {
  description = "Private IP address of the controller"
  value       = azurerm_network_interface.controller_nic.private_ip_address
}

output "controller_nsg_id" {
  description = "ID of the controller network security group"
  value       = azurerm_network_security_group.controller_nsg.id
}

output "agent_nsg_id" {
  description = "ID of the agent network security group"
  value       = azurerm_network_security_group.agent_nsg.id
}

output "key_vault_id" {
  description = "ID of the Key Vault (if enterprise config is enabled)"
  value       = local.enable_enterprise ? azurerm_key_vault.velda_kv[0].id : null
}

output "app_configuration_id" {
  description = "ID of the App Configuration store"
  value       = azurerm_app_configuration.velda_config.id
}

output "app_configuration_endpoint" {
  description = "Endpoint of the App Configuration store"
  value       = azurerm_app_configuration.velda_config.endpoint
}
