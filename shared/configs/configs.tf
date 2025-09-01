locals {
  envoy_config = (var.enterprise_config == null ? "" :
    templatefile("${path.module}/envoy.yaml", {
      domain        = var.enterprise_config.domain,
      https_enabled = var.enterprise_config.https_certs != null,
  }))
  setup_configs = local.enable_enterprise ? jsonencode({
    instance_id = var.name
    zfs_disks   = var.zfs_disks
  }) : ""
}


output "setup_script" {
  value = (local.enable_enterprise ? <<-EOT
  cat <<-EOF  > /tmp/velda-setup.json
  ${local.setup_configs}
  EOF
  /opt/velda/bin/setup.sh /tmp/velda-setup.json
  EOT
    : <<-EOT
cat <<-EOF > /etc/velda.yaml
${local.controller_config}
EOF
# ZFS setup
zpool import -f zpool || zpool create zpool /dev/disk/by-id/google-zfs || zpool status zpool
zfs create zpool/images || zfs wait zpool/images
EOT
  )
}

output "extra_configs" {
  value = local.enable_enterprise ? tomap({
      "envoy-config"   = jsonencode(yamldecode(local.envoy_config))
      "velda-config"   = yamlencode(local.controller_config)
      "velda-instance" = var.name
  }) : tomap({})
}
