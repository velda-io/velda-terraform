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
  is_enterprise     = startswith(local.image_version, "ent-") || startswith(local.image_version, "dev-ent-")
  image_project     = local.is_enterprise ? "velda-ent" : "velda-oss"
  has_gpu           = (var.accelerator_type != null && var.accelerator_count > 0) || startswith(var.instance_type, "a") || startswith(var.instance_type, "g")
  upgrade_script    = var.upgrade_agent_on_start == null ? "" : <<-EOT
    echo "Upgrading agent on start..."
    gsutil cp "${var.upgrade_agent_on_start}" velda
    chmod +x velda
    cp -f velda /usr/bin/velda
    EOT
  agent_config = yamlencode({
    broker         = var.controller_output.broker_info
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

    # Setup localssd for agent empty-dir space.
    # 1. Identify disks matching the local SSD pattern.
    SSD_DEVICES=$(ls /dev/disk/by-id/google-local-*ssd-* 2>/dev/null || true)

    if [ -z "$SSD_DEVICES" ] ; then
      echo "No Local SSDs found matching 'local-ssd-'. Skipping RAID setup."
    else
      DEVICE_COUNT=$(echo "$SSD_DEVICES" | wc -w)
      echo "Found $DEVICE_COUNT Local SSDs. Configuring RAID 0..."

      # Create RAID 0 array (md0)
      # --run allows it to start without manual confirmation
      # --force to make it work with single disk for simplicity.
      mdadm --create /dev/md0 --level=0 --raid-devices=$DEVICE_COUNT $SSD_DEVICES --force --run

      # Create Filesystem
      mkfs.ext4 -F /dev/md0

      # Mount at /tmp/agent
      mkdir -p /tmp/agent
      mount /dev/md0 /tmp/agent
    fi

    systemctl start velda-agent
    EOT
}

resource "google_compute_instance_template" "agent_template" {
  project        = var.controller_output.project
  name_prefix    = "${var.controller_output.name}-agent-${var.pool}-"
  machine_type   = var.instance_type
  can_ip_forward = false

  disk {
    source_image = (local.image_version != "latest" ?
      "projects/${local.image_project}/global/images/velda-agent-${local.image_version}" :
    "projects/${local.image_project}/global/images/family/velda-agent")
    auto_delete  = true
    disk_size_gb = var.boot_disk_size_gb
    disk_type    = var.boot_disk_type
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
    for_each = local.has_gpu && var.accelerator_type != null ? [1] : []
    content {
      type  = var.accelerator_type
      count = var.accelerator_count
    }
  }

  dynamic "disk" {
    for_each = var.localssd_count > 0 ? toset(range(var.localssd_count)) : []
    // Local SSD (Scratch Disk)
    content {
      disk_type    = "local-ssd"
      type         = "SCRATCH"
      interface    = "NVME"
      device_name  = "local-ssd-${disk.value}"
      disk_size_gb = 375 # Each local SSD is 375GB
    }
  }

  scheduling {
    on_host_maintenance         = local.has_gpu ? "TERMINATE" : "MIGRATE"
    preemptible                 = var.preemptible
    provisioning_model          = var.preemptible ? "SPOT" : "STANDARD"
    automatic_restart           = var.preemptible ? false : true
    instance_termination_action = var.preemptible ? "STOP" : null
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
  project            = var.controller_output.project
  name               = "${var.controller_output.name}-agent-${var.pool}"
  base_instance_name = "${var.controller_output.name}-agent"
  zone               = var.controller_output.zone
  version {
    instance_template = google_compute_instance_template.agent_template.self_link
  }
}
