locals {
  enable_enterprise = var.enterprise_config != null
  controller_config = (merge(
    var.extra_config,
    {
      server = merge({
        grpc_address = ":50051"
        http_address = ":8081"
        },
        local.enable_enterprise ? { host = var.enterprise_config.domain } : {},
        local.enable_enterprise ? { use_https = var.enterprise_config.https_certs != null } : {},
        local.enable_enterprise ? { storage_grpc_endpoint = ":50052" } : {},
        local.enable_enterprise ? var.enterprise_config.app_domain != null ? {
          app_domain         = var.enterprise_config.app_domain
          app_listen_address = ":8082"
        } : {} : {},
        lookup(var.extra_config, "server", {})
      )

      storage = {
        zfs = {
          pool = "zpool"
        }
      }
      provisioners = var.provisioners
    },
    local.enable_enterprise ? {
      database = {
        sql = {
          driver = "pgx"
          url    = var.postgres_url
        }
      }
    } : {},
    local.enable_enterprise ? {
      user_auth = merge({
        access_token_private_key = "/run/velda/access-token-private-key.pem"
        access_token_public_key  = "/run/velda/access-token-public-key.pem"
        saml = {
          sp_cert_path = "/run/velda/saml.pub"
          sp_key_path  = "/run/velda/saml"
        }
      }, lookup(var.extra_config, "user_auth", {}))
    } : {},
    var.use_proxy ? {
      jump_server = merge({
        listen_address   = ":2222"
        host_private_key = "/run/velda/jumphost"
        public_address   = "${var.enterprise_config.domain}:2222"
        host_public_key  = "/run/velda/jumphost.pub"
      }, lookup(var.extra_config, "jump_server", {}))
    } : {},
  ))
}
