locals {
  cloud_init_yaml = yamldecode(templatefile("${path.module}/cloud-init-controller.tftpl", {
    admin_ssh_key     = var.admin_ssh_keys
    enable_https      = var.enterprise_config != null && var.enterprise_config.https_certs != null
    postgres_password = var.postgres_url != null ? null : random_password.postgres[0].result
    velda_config      = yamlencode(local.controller_config)
    init_config = jsonencode({
      instance_id          = var.name
      full_init            = true
      velda_version        = var.controller_version
      base_instance_images = var.base_instance_images
      zfs_disks            = var.zfs_disks
      domain               = var.enterprise_config != null ? var.enterprise_config.domain : null
    })
    https_cert = var.enterprise_config != null && var.enterprise_config.https_certs != null ? var.enterprise_config.https_certs.cert : null
    https_key  = var.enterprise_config != null && var.enterprise_config.https_certs != null ? var.enterprise_config.https_certs.key : null
  }))

  cloud_init_final = merge(
    local.cloud_init_yaml,
    {
      packages = concat(
        lookup(local.cloud_init_yaml, "packages", []),
        var.extra_cloud_init.packages
      ),
      runcmd = concat(
        lookup(local.cloud_init_yaml, "runcmd", []),
        var.extra_cloud_init.runcmd
      ),
      write_files = concat(
        lookup(local.cloud_init_yaml, "write_files", []),
        var.extra_cloud_init.write_files
      ),
    }
  )
}

output "cloud_init" {
  value       = "#cloud-config\n${yamlencode(local.cloud_init_final)}"
  description = "Cloud-init configuration for Velda controller"
}
