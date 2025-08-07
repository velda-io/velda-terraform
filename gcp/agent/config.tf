locals {
  pool_config = {
    name = var.pool,
    auto_scaler = merge(
      var.autoscale_config,
      {
        backend = {
          gce_instance_group = {
            project = var.controller_output.project
            zone    = var.controller_output.zone
            instance_group = google_compute_instance_group_manager.agent_group.name
          }
        }
      }
    )
  }
}

resource "google_storage_bucket_object" "config" {
  name   = "${var.controller_output.config_gcs_prefix}${var.pool}"
  bucket = var.controller_output.config_gcs_bucket
  content = yamlencode(local.pool_config)
}