locals {
  project = "<Project-ID>" # Update to your GCP project
  region  = "us-central1"
  zone    = "us-central1-a"
  gke_cluster_name = "<cluster-name>"
}
provider "google" {
  project = local.project
}

module "controller" {
  source     = "github.com/velda-io/velda-terraform//gcp/controller"
  project    = local.project
  zone       = local.zone
  subnetwork = "projects/${local.project}/regions/${local.region}/subnetworks/default"

  data_disk_size = 100
  controller_machine_type = "e2-medium"
  data_disk_type = "pd-ssd"

  extra_provisioners = [
    {
      kubernetes = {
        namespace = "default"
        gke = {
          project    = local.project
          location   = local.zone
          cluster_name = local.gke_cluster_name
        }
      }
    }
  ]
}

resource "google_project_iam_member" "controller_instance_manage" {
  project = local.project
  role    = "roles/container.developer"

  member = "serviceAccount:${module.controller.controller_sa}"
}