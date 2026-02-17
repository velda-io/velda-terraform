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
    broker         = var.controller_output.broker_info
    sandbox_config = var.sandbox_config
    daemon_config  = var.daemon_config
    pool           = var.pool
  })

  # Use bootcmd to run it earlier.
  cloud_init = yamlencode({
    bootcmd = concat(
      var.init_script_content != null ? [["cloud-init-per", "once", "veldainit", "/bin/bash", "-c", var.init_script_content]] : [],
      [
        "mkdir -p /run/velda",
        <<-EOT
      cat <<EOF > /run/velda/velda.yaml
      ${local.agent_config}
      EOF
      EOT
    ])
  })
  agent_version = var.agent_version != null ? var.agent_version : var.controller_output.agent_version
}

data "aws_ami" "velda_controller" {
  most_recent = true

  filter {
    name   = "name"
    values = ["velda-agent-${local.agent_version}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["686255976885"]
}

resource "aws_launch_template" "agent" {
  name          = "${var.controller_output.name}-agent-${var.pool}"
  image_id      = var.agent_ami != null ? var.agent_ami : data.aws_ami.velda_controller.id
  instance_type = var.instance_type

  network_interfaces {
    subnet_id                   = var.controller_output.subnet_ids[0]
    associate_public_ip_address = var.controller_output.use_nat ? false : true
    security_groups             = var.controller_output.security_group_ids
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.boot_disk_size
      volume_type = "gp2"
    }
  }

  private_dns_name_options {
    hostname_type = "resource-name"
  }

  dynamic "iam_instance_profile" {
    for_each = var.controller_output.instance_profile != "" ? [1] : []
    content {
      name = var.controller_output.instance_profile
    }
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
