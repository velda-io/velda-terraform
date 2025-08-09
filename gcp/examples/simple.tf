locals {
  project = "[YOUR_PROJECT_ID]"
  zone = "us-west1-a"
  region = "us-west1"
}
provider "google" {
  project = local.project
}

module "velda_controller" {
  source     = "github.com/velda-io/velda-terraform.git//gcp/controller?ref=main"
  project    = local.project
  zone       = local.zone
  subnetwork = "projects/${local.project}/regions/${local.region}/subnetworks/default"

  data_disk_size = 100
  controller_machine_type = "e2-medium"
  data_disk_type = "pd-ssd"
}

module "pool_shell" {
  source     = "github.com/velda-io/velda-terraform.git//gcp/agent?ref=main"

  pool              = "shell"
  controller_output = module.velda_controller.agent_configs

  instance_type = "e2-medium"
  agent_image_version = "0-0-1-test1"
  autoscale_config = {
    max_agents         = 5
    min_idle_agents    = 0
    max_idle_agents    = 2
    idle_decay         = "180s"
    initial_delay      = "30s"
    sync_loop_interval = "60s"
  }
}
