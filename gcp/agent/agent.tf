terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.15.0"
    }
  }
}

locals {
  has_gpu = var.accelerator_type != null && var.accelerator_count > 0
  upgrade_script = <<-EOT
    echo "Upgrading agent on start..."
    gsutil cp gs://novahub-release/client-oss-latest-amd64 velda-agent
    chmod +x velda-agent
    cp velda-agent /bin/velda-agent
EOT
  agent_config = yamlencode({
    broker = {
      address = "${var.controller_output.controller_ip}:50051"
    }
    sandbox_config = var.sandbox_config
    daemon_config = var.daemon_config
    pool = var.pool
  })
}
resource "google_compute_instance_template" "agent_template" {
  name_prefix    = "${var.controller_output.name}-agent-${var.pool}-"
  machine_type   = var.instance_type
  can_ip_forward = false

  disk {
    source_image = var.agent_image_version != null ? "projects/velda-oss/global/images/velda-agent-${var.agent_image_version}" : "projects/velda-oss/global/images/family/velda-controller"
    auto_delete  = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
    boot         = true
  }

  network_interface {
    subnetwork = var.controller_output.subnetwork

    // Only allocate a public IP if the NAT gateway is not used
    dynamic "access_config" {
      for_each = var.controller_output.use_nat_gateway ? [] : [1]
      content {
        network_tier = "STANDARD"
      }
    }
  }

  dynamic "guest_accelerator" {
    for_each = local.has_gpu ? [1] : []
    content {
      type  = var.accelerator_type
      count = var.accelerator_count
    }
  }

  scheduling {
    on_host_maintenance = local.has_gpu ? "TERMINATE" : "MIGRATE"
  }

  service_account {
    email  = var.controller_output.agent_service_account
    scopes = ["cloud-platform"]
  }

  metadata = {
      startup-script = <<-EOT
      #!/bin/bash
      set -euo pipefail
      ${var.upgrade_agent_on_start ? local.upgrade_script : ""}
      mkdir -p /tmp/agentdisk/0
      mount -t nfs -o async,rw ${var.controller_output.controller_ip}:/zpool /tmp/agentdisk/0
      mkdir -p /run/velda
      cat <<EOF > /run/velda/velda.yaml
      ${local.agent_config}
      EOF
      EOT
  }

  tags = ["${var.controller_output.name}-agent", "${var.pool}"]

  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_instance_group_manager" "agent_group" {
  name               = "${var.controller_output.name}-agent-${var.pool}"
  base_instance_name = "${var.controller_output.name}-agent"
  zone               = var.controller_output.zone
  version {
    instance_template = google_compute_instance_template.agent_template.self_link
  }
}
