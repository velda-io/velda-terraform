terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.15.0"
    }
  }
}

locals {
  image_version_raw = var.agent_image_version != null ? var.agent_image_version : (var.controller_output.default_agent_version != null ? var.controller_output.default_agent_version : "latest")
  image_version     = replace(local.image_version_raw, ".", "-")
  is_enterprise     = startswith(local.image_version, "ent-")
  image_project     = local.is_enterprise ? "velda-ent" : "velda-oss"
  has_gpu           = var.accelerator_type != null && var.accelerator_count > 0
  upgrade_script    = var.upgrade_agent_on_start == null ? "" : <<-EOT
    echo "Upgrading agent on start..."
    gsutil cp "${var.upgrade_agent_on_start}" velda
    chmod +x velda
    cp -f velda /bin/velda
    EOT
  agent_config = yamlencode({
    broker = {
      address = "${var.controller_output.controller_ip}:50051"
    }
    sandbox_config = var.sandbox_config
    daemon_config  = var.daemon_config
    pool           = var.pool
  })

  startup_script = <<-EOT
    #!/bin/bash
    ${local.upgrade_script}
    mkdir -p /run/velda
    cat <<EOF > /run/velda/velda.yaml
    ${local.agent_config}
    EOF
    EOT
}

resource "google_compute_instance_template" "agent_template" {
  name_prefix    = "${var.controller_output.name}-agent-${var.pool}-"
  machine_type   = var.instance_type
  can_ip_forward = false

  disk {
    source_image = (local.image_version != "latest" ?
      "projects/${local.image_project}/global/images/velda-agent-${local.image_version}" :
    "projects/${local.image_project}/global/images/family/velda-agent")
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
    startup-script = local.startup_script
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
