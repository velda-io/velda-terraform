terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.15.0"
    }
  }
}

locals {
  region = join("-", slice(split("-", var.zone), 0, 2))
}

data "google_compute_subnetwork" "selected" {
  self_link   = "https://www.googleapis.com/compute/v1/${var.subnetwork}"
}

locals {
  network = data.google_compute_subnetwork.selected.network
  enable_enterprise = var.enterprise_config != null
}