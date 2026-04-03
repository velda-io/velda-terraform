data "aws_subnet" "subnetwork" {
  id = var.subnet_ids[0]
}

resource "aws_ebs_volume" "controller_data" {
  availability_zone = data.aws_subnet.subnetwork.availability_zone
  size              = var.data_disk_size
  type              = var.data_disk_type
  tags = {
    Name = "${var.name}-data"
  }
  lifecycle {
    ignore_changes = [snapshot_id]
  }
}

resource "aws_volume_attachment" "controller_data_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.controller_data.id
  instance_id = aws_instance.controller.id
}

locals {
  download_url = "https://releases.velda.io/velda-${var.controller_version}-linux-amd64"
  use_nat      = var.external_access.use_nat
}

data "aws_ami" "velda_controller" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "controller" {
  ami                         = var.controller_ami != null ? var.controller_ami : data.aws_ami.velda_controller.id
  instance_type               = var.controller_machine_type
  subnet_id                   = var.controller_subnet_id
  associate_public_ip_address = !local.use_nat || var.external_access.use_controller_external_ip
  source_dest_check           = false

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  iam_instance_profile   = aws_iam_instance_profile.controller_profile.name
  vpc_security_group_ids = concat([aws_security_group.controller_sg.id], var.additional_controller_security_groups)

  tags = {
    Name = var.name
  }

  user_data = base64encode(module.config.cloud_init)

  lifecycle {
    ignore_changes        = [ami]
    create_before_destroy = true
  }
}

resource "aws_eip" "lb" {
  count    = var.external_access.use_eip ? 1 : 0
  instance = aws_instance.controller.id
  domain   = "vpc"
}

resource "aws_iam_instance_profile" "controller_profile" {
  name = "${var.name}-controller-profile"
  role = aws_iam_role.controller_role.name
}
