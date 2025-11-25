
# Data disk for controller
resource "nebius_compute_v1_disk" "controller_data" {
  parent_id        = var.parent_id
  name             = "${var.name}-data"
  block_size_bytes = 4096
  size_bytes       = var.data_disk_size * 1024 * 1024 * 1024 # Convert GB to bytes
  type             = var.data_disk_type
}

# Boot disk for controller
resource "nebius_compute_v1_disk" "controller_boot" {
  parent_id           = var.parent_id
  name                = "${var.name}-boot"
  block_size_bytes    = 4096
  size_bytes          = 20 * 1024 * 1024 * 1024 # 20 GiB
  type                = "NETWORK_SSD"
  source_image_family = { image_family = "ubuntu24.04-driverless" }

  lifecycle {
    ignore_changes = [source_image_family]
  }
}

# Controller instance
resource "nebius_compute_v1_instance" "controller" {
  parent_id = var.parent_id
  name      = var.name

  resources = {
    platform = var.controller_platform
    preset   = var.controller_preset
  }

  boot_disk = {
    attach_mode   = "READ_WRITE"
    existing_disk = nebius_compute_v1_disk.controller_boot
  }

  secondary_disks = [
    {
      device_id     = "data-disk"
      attach_mode   = "READ_WRITE"
      existing_disk = nebius_compute_v1_disk.controller_data
    }
  ]

  network_interfaces = var.network_interface

  service_account_id = nebius_iam_v1_service_account.controller_sa.id

  cloud_init_user_data = var.cloud_init
}

# Service account for controller
resource "nebius_iam_v1_service_account" "controller_sa" {
  parent_id = var.parent_id
  name      = "${var.name}-controller-sa"
}

resource "nebius_iam_v1_group_membership" "controller_member" {
  parent_id = var.sa_member_group
  member_id = nebius_iam_v1_service_account.controller_sa.id
}
