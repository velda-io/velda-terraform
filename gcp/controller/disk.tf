resource "google_compute_disk" "disk_volume" {
  project = var.project
  name    = "${var.name}-data"
  type    = var.data_disk_type
  zone    = var.zone
  size    = var.data_disk_size

  lifecycle {
    ignore_changes = [snapshot]
  }
}
