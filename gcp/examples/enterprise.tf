provider "google" {
}

module "controller" {
  source     = "github.com/velda-io/velda-terraform.git//gcp/controller?ref=main"
  name       = "velda-ent-test"
  project    = "velda-dev"
  zone       = "us-central1-b"
  subnetwork = "projects/velda-dev/regions/us-central1/subnetworks/default"

  data_disk_size          = 20
  controller_machine_type = "e2-medium"
  data_disk_type          = "pd-ssd"
  controller_version      = "ent-v1.1.2"

  enterprise_config = {
    domain       = "gcp.velda.cloud" # Update this to your domain
    organization = "Velda Inc"
  }
  external_access = {
    setup_firewall_rule = true
    use_proxy           = true
    use_nat             = false
  }

  use_nat_gateway = false
}

module "pool_shell" {
  source = "github.com/velda-io/velda-terraform.git//gcp/agent?ref=main"

  pool              = "shell"
  controller_output = module.controller.agent_configs

  instance_type = "e2-medium"
  autoscale_config = {
    max_agents         = 5
    min_idle_agents    = 0
    max_idle_agents    = 2
    idle_decay         = "180s"
    initial_delay      = "30s"
    sync_loop_interval = "60s"
  }
}
