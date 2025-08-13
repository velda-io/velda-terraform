provider "aws" {
  region = "us-east-1"
}
locals {
  ami_cpu = "ami-0dde797f91f7762cc"
  ami_gpu = "ami-0d1ccfca26e49759c"
}

module "controller" {
  source = "github.com/velda-io/velda-terraform.git//aws/controller?ref=main"
  name   = "velda"
  zone   = "us-east-1a"

  region               = "us-east-1"
  vpc_id               = "vpc-099ec8894a6afe7b7"
  subnet_ids           = ["subnet-0f41c0877ab63d9f5", "subnet-02b39788a1ad87f9d"]
  controller_subnet_id = "subnet-0f41c0877ab63d9f5"

  data_disk_size          = 100
  controller_machine_type = "t2.medium"
  controller_ami          = "ami-0c43f6c8bc5ee5be4"
}

module "pool-shell" {
  source = "github.com/velda-io/velda-terraform.git//aws/agent?ref=main"

  pool              = "shell"
  controller_output = module.controller.agent_configs

  instance_type = "t2.medium"
  agent_ami     = local.ami_cpu
  autoscale_config = {
    max_agents         = 5
    min_idle_agents    = 0
    max_idle_agents    = 2
    idle_decay         = "180s"
    initial_delay      = "30s"
    sync_loop_interval = "60s"
  }
  sandbox_config = {
  }
}

module "pool-gpu" {
  source = "github.com/velda-io/velda-terraform.git//aws/agent?ref=main"

  pool              = "gpu"
  controller_output = module.controller.agent_configs

  instance_type = "g4dn.xlarge"
  agent_ami     = local.ami_gpu
  autoscale_config = {
    max_agents         = 5
    min_idle_agents    = 0
    max_idle_agents    = 2
    idle_decay         = "180s"
    initial_delay      = "30s"
    sync_loop_interval = "60s"
  }
  sandbox_config = {
    nvidia_driver_install_dir = "/var/nvidia"
  }
}
