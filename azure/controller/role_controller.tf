resource "azurerm_user_assigned_identity" "controller_identity" {
  name                = "${var.name}-controller-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Grant controller VM access to manage resources
resource "azurerm_role_assignment" "controller_contributor" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.controller_identity.principal_id
}

# Grant controller VM access to read App Configuration
resource "azurerm_role_assignment" "controller_appconfig_reader" {
  scope                = azurerm_app_configuration.velda_config.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.controller_identity.principal_id
}

resource "azurerm_role_assignment" "terraform_appconfig_writer" {
  scope                = azurerm_app_configuration.velda_config.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Custom role for managing VMs with specific tags
resource "azurerm_role_definition" "velda_vm_manager" {
  name  = "${var.name}-vm-manager"
  scope = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/write",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/delete",
      "Microsoft.Network/networkInterfaces/*",
      "Microsoft.Network/publicIPAddresses/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  ]
}

resource "azurerm_role_assignment" "controller_vm_manager" {
  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  role_definition_id = azurerm_role_definition.velda_vm_manager.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.controller_identity.principal_id
}
