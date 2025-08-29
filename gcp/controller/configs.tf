locals {
  controller_config = yamlencode({
    server = {
      grpc_address = ":50051"
      http_address = ":8081"
    }

    storage = {
      zfs = {
        pool = "zpool"
      }
    }
    provisioners = concat([
      {
        gcs = {
          bucket          = google_storage_bucket.pool_configs.name
          config_prefix   = "pools"
          update_interval = "60s"
        },
      }
    ], var.extra_provisioners)
  })
}
