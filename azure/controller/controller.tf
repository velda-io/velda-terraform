data "azurerm_subnet" "controller_subnet" {
  name                 = split("/", var.controller_subnet_id)[10]
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_managed_disk" "controller_data" {
  name                 = "${var.name}-data-disk"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size

  tags = {
    Name = "${var.name}-data"
  }

  lifecycle {
    ignore_changes = [source_resource_id]
  }
}

locals {
  image_name      = local.enable_enterprise ? "velda-controller-ent" : "velda-${var.controller_version}"
  release_storage = "veldarelease"
  download_url    = local.enable_enterprise || startswith(var.controller_version, "dev") ? "https://velda-release.s3.us-west-1.amazonaws.com/velda-${var.controller_version}-linux-amd64" : "https://github.com/velda-io/velda/releases/download/${var.controller_version}/velda-${var.controller_version}-linux-amd64"
  use_nat         = var.external_access.use_nat_gateway
}

/*
data "azurerm_image" "velda_controller" {
  count               = var.controller_image == null ? 1 : 0
  name                = local.image_name
  resource_group_name = "velda-images"
}
*/

resource "azurerm_network_interface" "controller_nic" {
  name                = "${var.name}-controller-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.controller_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.external_access.use_controller_external_ip ? azurerm_public_ip.controller_pip[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "controller_nic_nsg" {
  network_interface_id      = azurerm_network_interface.controller_nic.id
  network_security_group_id = azurerm_network_security_group.controller_nsg.id
}

resource "azurerm_public_ip" "controller_pip" {
  count               = var.external_access.use_controller_external_ip ? 1 : 0
  name                = "${var.name}-controller-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "tls_private_key" "controller_ssh" {
  count     = var.controller_ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "controller" {
  name                = "${var.name}-controller"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.controller_vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.controller_nic.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.controller_ssh_public_key != null ? var.controller_ssh_public_key : tls_private_key.controller_ssh[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  #source_image_id = var.controller_image == null ? data.azurerm_image.velda_controller[0].id : null
  source_image_id = "/subscriptions/5649ba05-9444-4b27-b4a0-c2d863bc0a3a/resourceGroups/velda-images/providers/Microsoft.Compute/galleries/velda_gallery/images/velda"

  dynamic "source_image_reference" {
    for_each = var.controller_image != null ? [var.controller_image] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.controller_identity.id]
  }

  custom_data = base64encode(templatefile("${path.module}/data/cloud-init.yaml", {
    velda_jump_keys = var.jumphost_public_keys
    setup_script    = <<-EOF
#!/bin/bash
set -eux

if ! [ -e $(which velda) ] || [ "$(velda version)" != "${var.controller_version}" ]; then
  curl -Lo velda ${local.download_url}
  chmod +x velda
  cp -f velda /usr/bin/velda
fi

${module.config.setup_script}
EOF
  }))

  tags = {
    Name = var.name
  }

  lifecycle {
    ignore_changes = [source_image_id, source_image_reference]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "controller_data_attach" {
  managed_disk_id    = azurerm_managed_disk.controller_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.controller.id
  lun                = 0
  caching            = "ReadWrite"
}
