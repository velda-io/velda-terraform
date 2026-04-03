locals {
  cloud_init_yaml = var.enterprise_config == null ? yamlencode({
    users = [
      {
        name                = "velda-admin"
        gecos               = "Velda User"
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        groups              = ["sudo", "adm", "docker"]
        shell               = "/bin/bash"
        ssh_authorized_keys = var.admin_ssh_keys
      },
      {
        name                = "velda"
        gecos               = "Velda User"
        shell               = "/bin/bash"
        ssh_authorized_keys = var.access_ssh_keys != null ? var.access_ssh_keys : var.admin_ssh_keys
      },
      {
        name                = "velda_jump"
        gecos               = "Velda Jump User"
        shell               = "/usr/sbin/nologin"
        ssh_authorized_keys = var.access_ssh_keys != null ? var.access_ssh_keys : var.admin_ssh_keys
      },
    ]

    bootcmd = [<<-EOF
      #!/bin/bash
      # This is only used for upgrade, not for new setup.
      if (command -v velda) && [ "$(velda version)" != "${var.controller_version}" ]; then
        curl -fsSL -o /tmp/velda "https://releases.velda.io/velda-${var.controller_version}-linux-amd64"
        chmod +x /tmp/velda
        mv /tmp/velda /usr/bin/velda
      fi
      EOF
    ]

    package_update  = true
    package_upgrade = false
    packages = concat([
      "docker.io",
      "zfsutils-linux",
      "nfs-kernel-server",
      "unzip",
      "jq",
      "curl",
    ], var.extra_cloud_init.packages)

    write_files = concat([
      {
        path        = "/etc/velda/init.yaml"
        owner       = "root:root"
        permissions = "0644"
        content = jsonencode({
          instance_id   = var.name
          full_init     = true
          velda_version = var.controller_version
          zfs_disks     = var.zfs_disks
          domain        = null
        })
      },
      {
        path        = "/etc/velda/config.yaml"
        owner       = "root:root"
        permissions = "0644"
        content     = yamlencode(local.controller_config)
      },
      {
        path        = "/etc/ssh/sshd_config.d/90-velda.conf"
        owner       = "root:root"
        permissions = "0644"
        content     = <<-EOT
          Match User velda
            AcceptEnv VELDA_INSTANCE
            ForceCommand /usr/bin/velda run --ssh --
        EOT
      },
      {
        path        = "/tmp/velda-setup.sh"
        owner       = "root:root"
        permissions = "0755"
        content     = file("${path.module}/setup-oss.sh")
      },
    ], var.extra_cloud_init.write_files)

    runcmd = concat([
      "systemctl restart ssh",
      "bash /tmp/velda-setup.sh /etc/velda/init.yaml",
      "sudo -u velda-admin velda init --broker http://localhost:50051",
      "sudo -u velda velda init --broker http://localhost:50051",
    ], var.extra_cloud_init.runcmd)
    }) : yamlencode({
    users = [
      {
        name                = "velda-admin"
        gecos               = "Velda User"
        sudo                = "ALL=(ALL) NOPASSWD:ALL"
        groups              = ["sudo", "adm", "docker"]
        shell               = "/bin/bash"
        ssh_authorized_keys = var.admin_ssh_keys
      },
    ]

    package_update  = true
    package_upgrade = false
    packages = concat([
      "docker.io",
      "zfsutils-linux",
      "nfs-kernel-server",
      "unzip",
      "postgresql-client",
      "jq",
      "curl",
    ], var.extra_cloud_init.packages)

    write_files = concat(
      var.enterprise_config.https_certs != null ? [
        {
          path        = "/etc/velda/envoy/cert.pem"
          owner       = "root:root"
          permissions = "0600"
          content     = var.enterprise_config.https_certs.cert
        },
        {
          path        = "/etc/velda/envoy/key.pem"
          owner       = "root:root"
          permissions = "0600"
          content     = var.enterprise_config.https_certs.key
        },
      ] : [],
      [
        {
          path        = "/etc/velda/init.yaml"
          owner       = "root:root"
          permissions = "0644"
          content = jsonencode({
            instance_id   = var.name
            full_init     = true
            velda_version = var.controller_version
            zfs_disks     = var.zfs_disks
            domain        = var.enterprise_config.domain
          })
        },
        {
          path        = "/etc/velda/config.yaml"
          owner       = "root:root"
          permissions = "0644"
          content     = yamlencode(local.controller_config)
        },
      ],
      var.extra_cloud_init.write_files
    )

    runcmd = concat(
      [
        "curl \"https://releases.velda.io/setup.sh\" -o \"/tmp/velda-setup.sh\"",
      ],
      var.postgres_url != null ? [] : [
        "docker run -d --restart=always --name pg -e POSTGRES_PASSWORD=${random_password.postgres[0].result} -p 127.0.0.1:5432:5432 -v pg-data:/var/lib/postgresql/data postgres:17-alpine",
      ],
      [
        "bash /tmp/velda-setup.sh /etc/velda/init.yaml",
      ],
      var.extra_cloud_init.runcmd
    )
  })

  # Legacy shared/configs-compatible outputs.
  legacy_envoy_config = (var.enterprise_config == null ? "" :
    templatefile("${path.module}/../configs/envoy.yaml", {
      domain        = var.enterprise_config.domain,
      https_enabled = var.enterprise_config.https_certs != null,
      app_domain    = try(var.enterprise_config.app_domain, null),
    })
  )

}

output "cloud_init" {
  value       = "#cloud-config\n${local.cloud_init_yaml}"
  description = "Cloud-init configuration for Velda controller"
}

output "controller_config" {
  value       = local.controller_config
  description = "Velda controller configuration"
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
    "envoy-config"   = jsonencode(yamldecode(local.legacy_envoy_config))
    "velda-config"   = yamlencode(local.controller_config)
    "velda-instance" = var.name
  }) : tomap({})
  description = "Legacy extra configs map compatible with shared/configs"
}
