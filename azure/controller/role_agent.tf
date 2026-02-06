data "azurerm_user_assigned_identity" "agent_identity" {
  count               = var.agent_identity_override != null ? 1 : 0
  name                = var.agent_identity_override
  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "agent_identity" {
  count               = var.agent_identity_override == null ? 1 : 0
  name                = "${var.name}-agent-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
}

locals {
  agent_identity_id           = var.agent_identity_override != null ? data.azurerm_user_assigned_identity.agent_identity[0].id : azurerm_user_assigned_identity.agent_identity[0].id
  agent_identity_principal_id = var.agent_identity_override != null ? data.azurerm_user_assigned_identity.agent_identity[0].principal_id : azurerm_user_assigned_identity.agent_identity[0].principal_id
}
