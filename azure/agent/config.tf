locals {
  pool_config = {
    name = var.pool,
    auto_scaler = merge(
      var.autoscale_config,
      {
        backend = {
          azure_vmss = {
            subscription_id = var.controller_output.subscription_id
            resource_group  = var.controller_output.resource_group
            vmss_name       = "${var.controller_output.name}-agent-${var.pool}"
          }
        }
      }
    )
  }
}

resource "azurerm_app_configuration_key" "agent_config" {
  configuration_store_id = var.controller_output.app_configuration_id
  key                    = "pools/${var.pool}"
  value                  = yamlencode(local.pool_config)
}
