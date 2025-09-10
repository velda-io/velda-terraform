locals {
  public_address_protocol = var.enterprise_config.https_certs != null ? "https" : "http"
}

// Provide this output to the agent module.
output "agent_configs" {
  value = {
    project       = var.project
    name          = var.name
    zone          = var.zone
    subnetwork    = var.subnetwork
    broker_info = {
      address        = "${google_compute_address.internal_ip.address}:50051"
      public_address = var.enterprise_config != null ? "${local.public_address_protocol}://${var.enterprise_config.domain}" : ""
    }

    agent_service_account = google_service_account.agent_sa.email
    use_nat_gateway       = var.use_nat_gateway

    config_gcs_bucket = google_storage_bucket.pool_configs.name
    config_gcs_prefix = "pools/"

    default_agent_version = var.controller_version
  }
}

output "controller_sa" {
  value = google_service_account.controller_sa.email
}

output "controller_ip" {
  value = google_compute_address.internal_ip.address
}