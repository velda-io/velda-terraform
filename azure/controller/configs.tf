module "config" {
  source = "../../shared/configs"

  name              = var.name
  enterprise_config = var.enterprise_config
  postgres_url      = local.postgres_url

  provisioners = concat([{
    azure = {
      endpoint        = azurerm_app_configuration.velda_config.endpoint
      config_prefix   = "pools"
      update_interval = "60s"
    }
  }], var.extra_provisioners)
  use_proxy = local.use_proxy
  zfs_disks = ["/dev/disk/azure/data/by-lun/0"]

  extra_config = var.extra_config
}

resource "azurerm_app_configuration" "velda_config" {
  name                = "${var.name}-appconfig-${substr(md5(var.resource_group_name), 0, 8)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "standard"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_app_configuration_key" "configs" {
  for_each               = module.config.extra_configs
  configuration_store_id = azurerm_app_configuration.velda_config.id
  key                    = "${var.name}/${each.key}"
  value                  = each.value
}
