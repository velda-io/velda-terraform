locals {
  envoy_config = (var.enterprise_config == null ? "" :
    templatefile("${path.module}/envoy.yaml", {
      domain        = var.enterprise_config.domain,
      https_enabled = var.enterprise_config.https_certs != null,
      app_domain    = var.enterprise_config.app_domain,
  }))
  setup_configs = local.enable_enterprise ? jsonencode({
    instance_id = var.name
    zfs_disks   = var.zfs_disks
  }) : ""
}
