terraform {
  required_providers {
    nebius = {
      source  = "terraform-provider.storage.eu-north1.nebius.cloud/nebius/nebius"
      version = ">= 0.5.55"
    }
  }
}

provider "nebius" {
  # Authentication is handled via NEBIUS_IAM_TOKEN environment variable
  # or Nebius CLI credentials
}

# Example OSS deployment
module "velda_oss" {
  source = "../" # Path to the nebius controller module

  name               = "velda-oss"
  region             = "eu-north1"
  parent_id          = var.parent_id
  subnet_id          = var.subnet_id
  controller_version = "1.0.0"

  controller_platform = "cpu-d3"
  controller_preset   = "4vcpu-16gb"

  data_disk_size = 50
  data_disk_type = "NETWORK_SSD"

  use_public_ip = true

  extra_config = {
    # Add any additional controller configuration here
  }
}

# Example Enterprise deployment with static IPs
module "velda_enterprise" {
  source = "../" # Path to the nebius controller module

  name               = "velda-ent"
  region             = "eu-north1"
  parent_id          = var.parent_id
  subnet_id          = var.subnet_id
  controller_version = "1.0.0"

  controller_platform = "cpu-d3"
  controller_preset   = "8vcpu-32gb"

  data_disk_size = 100
  data_disk_type = "NETWORK_SSD"

  use_static_ip        = true
  use_public_ip        = true
  use_static_public_ip = true

  enterprise_config = {
    domain       = "velda.example.com"
    organization = "Example Corp"
    sql_db       = "postgresql://user:password@host:5432/velda?sslmode=require"
    https_certs = {
      cert = file("${path.module}/certs/velda.crt")
      key  = file("${path.module}/certs/velda.key")
    }
  }

  extra_provisioners = [
    # Add additional provisioners if needed
    # {
    #   kubernetes = {
    #     kubeconfig_path = "/path/to/kubeconfig"
    #     namespace       = "default"
    #   }
    # }
  ]

  connection_source = [
    {
      name = "office"
      cidr = "203.0.113.0/24"
    },
    {
      name = "vpn"
      cidr = "10.0.0.0/8"
    }
  ]
}

# Variables
variable "parent_id" {
  description = "Nebius project ID"
  type        = string
}

variable "subnet_id" {
  description = "Nebius subnet ID"
  type        = string
}

# Outputs
output "oss_controller_ip" {
  description = "OSS Controller public IP"
  value       = module.velda_oss.controller_public_ip
}

output "oss_controller_private_ip" {
  description = "OSS Controller private IP"
  value       = module.velda_oss.controller_private_ip
}

output "enterprise_controller_ip" {
  description = "Enterprise Controller public IP"
  value       = module.velda_enterprise.controller_public_ip
}

output "enterprise_controller_url" {
  description = "Enterprise Controller URL"
  value       = "https://${module.velda_enterprise.controller_public_ip}"
}
