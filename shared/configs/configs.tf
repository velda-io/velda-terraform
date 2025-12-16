locals {
  envoy_config = (var.enterprise_config == null ? "" :
    templatefile("${path.module}/envoy.yaml", {
      domain        = var.enterprise_config.domain,
      https_enabled = var.enterprise_config.https_certs != null,
      app_domain    = var.enterprise_config.app_domain,
  }))
  setup_configs = local.enable_enterprise ? jsonencode({
    instance_id          = var.name
    zfs_disks            = var.zfs_disks
    base_instance_images = var.base_instance_images
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
${yamlencode(local.controller_config)}
EOF
# ZFS setup

zfs_disks='${join(" ", var.zfs_disks)}'
timeout=300
interval=2
start_time=$(date +%s)
for disk in $zfs_disks; do
  while [ ! -b "$disk" ]; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    if [ "$elapsed" -ge "$timeout" ]; then
      echo "Timeout waiting for disk $disk to appear."
      exit 1
    fi
    sleep $interval
  done
done

zpool import -f zpool || zpool create zpool $${zfs_disks} || zpool status zpool
zfs create zpool/images || zfs wait zpool/images
systemctl enable velda-apiserver
systemctl start velda-apiserver&
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
