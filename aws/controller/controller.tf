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
}

resource "aws_volume_attachment" "controller_data_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.controller_data.id
  instance_id = aws_instance.controller.id
}

resource "aws_instance" "controller" {
  ami                         = var.controller_ami
  instance_type               = var.controller_machine_type
  subnet_id                   = var.controller_subnet_id
  associate_public_ip_address = var.use_nat ? false : true

  root_block_device {
    volume_size = 10
    volume_type = "gp2"
  }

  iam_instance_profile   = aws_iam_instance_profile.controller_profile.name
  vpc_security_group_ids = [aws_security_group.controller_sg.id]

  tags = {
    Name = var.name
  }

  user_data = templatefile("${path.module}/data/always_run.txt", {
    script = <<-EOF
#!/bin/bash
set -eux
cat <<-EOT > /etc/velda.yaml
${local.controller_config}
EOT

# ZFS setup
zpool import -f zpool || zpool create zpool /dev/xvdf || zpool status zpool
zfs create zpool/images || zfs wait zpool/images

systemctl enable velda-apiserver
systemctl start velda-apiserver&
EOF
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "controller_profile" {
  name = "${var.name}-controller-profile"
  role = aws_iam_role.controller_role.name
}
