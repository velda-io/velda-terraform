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