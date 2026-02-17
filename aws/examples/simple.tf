variable "zone" {
  type        = string
  description = "The AWS availability zone to deploy Velda"
  default     = "us-east-1a"
}

variable "name" {
  type        = string
  description = "The name of the Velda deployment"
  default     = "velda"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ARN"
}

variable "subnet_ids" {
  type        = list(string)
  description = "The subnet ARNs for the controller and agents. For open-source, only the first subnet will be used."
}

variable "access_public_keys" {
  type        = list(string)
  description = "The public keys for accessing the Velda deployment"
}

variable "admin_public_keys" {
  type        = list(string)
  description = "The public keys for managing the Velda deployment"
}

locals {
  region = substr(var.zone, 0, length(var.zone) - 1)
}

provider "aws" {
  region = local.region
}

module "controller" {
  // Update to a specific commit if needed.
  source = "github.com/velda-io/velda-terraform.git//aws/controller?ref=main"
  name   = var.name
  region = local.region
  zone   = var.zone

  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  controller_subnet_id = var.subnet_ids[0]

  data_disk_size          = 100
  controller_machine_type = "t2.medium"
  // Check latest version from https://github.com/velda-io/velda/releases/
  controller_version = "v1.1.2"
  external_access = {
    use_nat = false
  }

  connection_source = [{
    cidr_ipv4 = "0.0.0.0/0"
  }]

  access_public_keys = var.access_public_keys
  admin_public_keys  = var.admin_public_keys
}

locals {
  default_autoscale_config = {
    max_agents         = 5
    min_idle_agents    = 0
    max_idle_agents    = 2
    idle_decay         = "180s"
    initial_delay      = "30s"
    sync_loop_interval = "60s"
  }
  default_sandbox_config = {
    disk_source = {
      nfs_mount_source = {
      }
    }
  }
}

module "pool-shell" {
  source = "github.com/velda-io/velda-terraform.git//aws/agent?ref=main"

  controller_output = module.controller.agent_configs

  pool          = "shell"
  instance_type = "t2.medium"

  autoscale_config = local.default_autoscale_config
  sandbox_config   = local.default_sandbox_config
}

module "pool-t4-1" {
  source = "github.com/velda-io/velda-terraform.git//aws/agent?ref=main"

  controller_output = module.controller.agent_configs

  pool          = "gpu-t4-1"
  instance_type = "g4dn.xlarge"

  autoscale_config = local.default_autoscale_config
  sandbox_config   = local.default_sandbox_config
}

module "pool-l4-1" {
  source = "github.com/velda-io/velda-terraform.git//aws/agent?ref=main"

  controller_output = module.controller.agent_configs

  pool          = "gpu-l4-1"
  instance_type = "g6.xlarge"

  autoscale_config = local.default_autoscale_config
  sandbox_config   = local.default_sandbox_config
}

output "instruction" {
  value = <<-EOT
    Velda deployment is created. To access the controller, use the following command to start an SSH session:

    ssh -i <path-to-private-key> velda-admin@${module.controller.controller_public_ip}
    velda instance create --docker-image ubuntu:24.04 my-instance

    To access to your instance
    ssh -o SetEnv=VELDA_INSTANCE=my-instance -i <path-to-access-private-key> velda@${module.controller.controller_public_ip}
  EOT
}
