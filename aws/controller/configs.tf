module "config" {
  source = "../../shared/configs"

  name              = var.name
  enterprise_config = var.enterprise_config
  postgres_url      = local.postgres_url

  provisioners = concat([{
    aws = {
      region          = var.region
      config_prefix   = "/${var.name}/pools"
      update_interval = "60s"
    }
  }], var.extra_provisioners)
  use_proxy = local.use_proxy
  zfs_disks = ["/dev/xvdf"]

  extra_config = var.extra_config
}

resource "aws_ssm_parameter" "configs" {
  for_each = module.config.extra_configs
  name     = "/${var.name}/${each.key}"
  type     = "String"
  value    = each.value
}
