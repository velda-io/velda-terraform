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
    provisioners = [
      {
        aws = {
          region          = var.region
          config_prefix   = "/${var.name}/pools"
          update_interval = "60s"
        }
      }
    ]
  })
}
