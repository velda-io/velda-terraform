locals {
  use_hyperdisk_boot_disk = startswith(var.controller_machine_type, "n4")
}
resource "google_compute_address" "internal_ip" {
  name         = "${var.name}-internal-ip"
  project      = var.project
  subnetwork   = var.subnetwork
  region       = local.region
  address_type = "INTERNAL"
}

resource "google_compute_instance" "controller" {
  project = var.project

  name = var.name

  attached_disk {
    device_name = "zfs"
    mode        = "READ_WRITE"

    source = google_compute_disk.disk_volume.self_link
  }

  boot_disk {
    auto_delete = true
    device_name = "${var.name}-bootdisk"

    initialize_params {
      image = var.controller_image_version != null ? "projects/velda-oss/global/images/velda-controller-${var.controller_image_version}" : "projects/velda-oss/global/images/family/velda-controller"
      size  = 10
      type  = local.use_hyperdisk_boot_disk ? "hyperdisk-balanced" : "pd-standard"
    }

    mode = "READ_WRITE"
  }
  machine_type = var.controller_machine_type

  network_interface {
    dynamic "access_config" {
      for_each = var.use_nat_gateway ? [] : [1]
      content {
        network_tier = var.external_access.network_tier
      }
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = var.subnetwork
    network_ip  = google_compute_address.internal_ip.address
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }
  service_account {
    email = data.google_service_account.controller_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  tags = [
    "${var.name}-server",
  ]

  metadata = {
    startup-script = <<EOF
#!/bin/bash
set -eux
cat <<-EOT > /etc/velda.yaml
${local.controller_config}
EOT

# ZFS setup
zpool import -f zpool || zpool create zpool /dev/disk/by-id/google-zfs || zpool status zpool
zfs create zpool/images || zfs wait zpool/images

exportfs  -o 'async,wdelay,hide,crossmnt,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash' '*:/zpool'
systemctl enable velda-apiserver
systemctl start velda-apiserver

EOF
  }

  zone = var.zone

  lifecycle {
    ignore_changes        = [metadata["ssh-keys"]]
    create_before_destroy = false
  }
}
