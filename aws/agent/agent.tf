terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
  }
}

locals {
  agent_config = yamlencode({
    broker = {
      address = "${var.controller_output.controller_ip}:50051"
    }
    sandbox_config = var.sandbox_config
    daemon_config  = var.daemon_config
    pool           = var.pool
  })

  cloud_init = yamlencode({
    bootcmd = [
      "mkdir -p /run/velda",
      <<-EOT
      cat <<EOF > /run/velda/velda.yaml
      ${local.agent_config}
      EOF
      EOT
    ]
  })
}

resource "aws_launch_template" "agent" {
  name          = "${var.controller_output.name}-agent-${var.pool}"
  image_id      = var.agent_ami
  instance_type = var.instance_type

  network_interfaces {
    subnet_id                   = var.controller_output.subnet_ids[0]
    associate_public_ip_address = var.controller_output.use_nat ? false : true
    security_groups             = var.controller_output.security_group_ids
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  iam_instance_profile {
    name = var.controller_output.instance_profile
  }
  tags = {
    VeldaApp = var.controller_output.name
    Pool     = var.pool
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      VeldaApp = var.controller_output.name
      Pool     = var.pool
    }
  }
  update_default_version = true

  user_data = base64encode("#cloud-config\n${local.cloud_init}")

  lifecycle {
    create_before_destroy = true
  }
}
