module "config" {
  source = "../../shared/configs"

  name              = var.name
  enterprise_config = var.enterprise_config
  postgres_url      = local.postgres_url

  provisioners = concat([{
    gcs = {
      bucket          = google_storage_bucket.pool_configs.name
      config_prefix   = "pools"
      update_interval = "60s"
    },
  }], var.extra_provisioners)
  use_proxy = local.use_proxy
  zfs_disks = ["/dev/disk/by-id/google-zfs"]
}
