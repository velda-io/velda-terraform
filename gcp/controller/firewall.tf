resource "google_compute_firewall" "allow_api_port" {
  count   = var.external_access.setup_firewall_rule ? 1 : 0
  name    = "${var.name}-api-access"
  network = local.network

  allow {
    protocol = "tcp"
    ports    = local.enable_enterprise ? ["80", "443", "2222"] : ["22", "50051"]
  }

  project       = data.google_compute_subnetwork.selected.project
  source_ranges = var.external_access.allowed_source_ranges
  source_tags   = var.external_access.allowed_source_tags
  target_tags   = ["${var.name}-server"]
}

resource "google_compute_firewall" "agent_access" {
  count   = var.external_access.setup_firewall_rule ? 1 : 0
  name    = "${var.name}-agent-access"
  project = data.google_compute_subnetwork.selected.project
  network = local.network

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "2222", "50051", "2049"]
  }

  source_tags = ["${var.name}-agent"]
  target_tags = ["${var.name}-server"]
}