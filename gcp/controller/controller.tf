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

locals {
  image_project  = local.enable_enterprise ? "velda-ent" : "velda-oss"
  image_family   = local.enable_enterprise ? "velda-controller-ent" : "velda-controller"
  release_bucket = local.enable_enterprise ? "velda-ent-release" : "velda-release"
  download_url   = "https://releases.velda.io/velda-${var.controller_version}-linux-amd64"
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
      image = (var.controller_image_version != null ? "projects/${local.image_project}/global/images/${local.image_family}-${var.controller_image_version}" :
      "projects/${local.image_project}/global/images/family/${local.image_family}")
      size = 20
      type = local.use_hyperdisk_boot_disk ? "hyperdisk-balanced" : "pd-standard"
    }

    mode = "READ_WRITE"
  }
  machine_type = var.controller_machine_type

  network_interface {
    dynamic "access_config" {
      for_each = var.use_nat_gateway ? [] : [1]
      content {
        network_tier = var.external_access.network_tier
        nat_ip       = var.external_access.server_ip_address
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
    email = google_service_account.controller_sa.email
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  tags = [
    "${var.name}-server",
  ]

  metadata = merge({
    startup-script = <<EOF
#!/bin/bash
set -eux

if ! [ -e $(which velda) ] || [ "$(velda version)" != "${var.controller_version}" ]; then
  curl -fsSL -o velda ${local.download_url}
  chmod +x velda
  cp -f velda /usr/bin/velda
fi

${module.config.setup_script}
EOF
  }, module.config.extra_configs)

  zone = var.zone

  lifecycle {
    ignore_changes        = [metadata["ssh-keys"]]
    create_before_destroy = false
  }
}
