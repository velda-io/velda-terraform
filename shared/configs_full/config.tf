locals {
  enable_enterprise = var.enterprise_config != null
  controller_config = (merge(
    {
      server = merge({
        grpc_address = ":50051"
        http_address = ":8081"
        },
        var.enterprise_config != null ? {
          host      = var.enterprise_config.domain
          use_https = var.enterprise_config.https_certs != null
        } : {}
      )
      storage = {
        zfs = {
          pool = "zpool"
        }
      }
    },
    var.enterprise_config != null ? tomap({
      database = {
        sql = {
          driver = "pgx"
          url    = local.postgres_url
        }
      }
      user_auth = {
        access_token_private_key = "/etc/velda/auth_keys"
        access_token_public_key  = "/etc/velda/auth_keys.pub"
        saml = {
          sp_cert_path = "/etc/velda/saml.cert"
          sp_key_path  = "/etc/velda/saml.key"
        }
      }
      jump_server = {
        listen_address   = ":2222"
        host_private_key = "/etc/velda/jumphost"
        public_address   = "${coalesce(var.enterprise_config.jump_server_addr, var.enterprise_config.domain)}:2222"
        host_public_key  = "/etc/velda/jumphost.pub"
      }
    }) : tomap({}),
    var.extra_config,
  ))
}
