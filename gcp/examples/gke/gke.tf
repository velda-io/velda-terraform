// Setup the GKE cluster.
resource "google_container_cluster" "velda_k8s_cluster" {
  name     = local.gke_cluster_name
  location = local.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  subnetwork = "projects/${local.project}/regions/${local.region}/subnetworks/default"

  // enable basic IP allocation (VPC-native clusters recommended)
  ip_allocation_policy {}

  // minimal logging and monitoring settings
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "primary" {
  name     = "primary-node-pool"
  cluster  = google_container_cluster.velda_k8s_cluster.name
  location = google_container_cluster.velda_k8s_cluster.location

  node_count = 0

  node_config {
    machine_type = "n1-standard-1"
    disk_size_gb = 20
    disk_type    = "pd-standard"

    // cloud-platform scope to allow broad APIs if needed by agents
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  // optional autoscaling could be added later; keep simple and fixed size for now
}
resource "google_compute_firewall" "allow_pod_cidr_to_velda_server" {
  name    = "allow-pod-cidr-to-velda-server"
  network = "projects/${local.project}/global/networks/default"

  allow {
    protocol = "all"
  }

  source_ranges = [google_container_cluster.velda_k8s_cluster.cluster_ipv4_cidr]
  target_tags   = ["velda-server"]
  direction     = "INGRESS"
  description   = "Allow all ingress from GKE pod CIDR to velda-server"
}