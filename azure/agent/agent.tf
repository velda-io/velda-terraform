terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
      [["cloud-init-per", "once", "agentname", "/bin/bash", "-c", <<-EOT
agentname=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r .compute.name)
sed -i "/^Type=/a Environment=AGENT_NAME=$agentname" /usr/lib/systemd/system/velda-agent.service
systemctl daemon-reload
EOT
      ]],
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

data "azurerm_shared_image_version" "velda_agent" {
  count               = var.agent_image_id == null ? 1 : 0
  gallery_name        = "velda_gallery"
  image_name          = "velda"
  name                = local.agent_version
  resource_group_name = "velda-images"
}

resource "azurerm_orchestrated_virtual_machine_scale_set" "agent" {
  name                = "${var.controller_output.name}-agent-${var.pool}"
  location            = var.controller_output.location
  resource_group_name = var.controller_output.resource_group

  sku_name  = var.vm_size
  instances = 0

  platform_fault_domain_count = 1

  source_image_id = var.agent_image_id != null ? var.agent_image_id : data.azurerm_shared_image_version.velda_agent[0].id

  os_profile {
    linux_configuration {
      disable_password_authentication = true
      admin_username                  = "velda-admin"

      admin_ssh_key {
        username   = "velda-admin"
        public_key = var.admin_ssh_public_key
      }
    }

    custom_data = base64encode("#cloud-config\n${local.cloud_init}")
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  network_interface {
    name    = "agent-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.controller_output.subnet_id

      application_security_group_ids               = [var.controller_output.application_security_group_id]
      load_balancer_backend_address_pool_ids       = []
      application_gateway_backend_address_pool_ids = []

      dynamic "public_ip_address" {
        for_each = var.controller_output.use_nat ? [] : [1]
        content {
          name = "agent-pip"
        }
      }
    }

    network_security_group_id = var.controller_output.security_group_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.controller_output.managed_identity_id]
  }

  tags = {
    VeldaApp = var.controller_output.name
    Pool     = var.pool
  }

  lifecycle {
    ignore_changes = [instances]
  }
}
