terraform {
  required_providers {
    nebius = {
      source  = "terraform-provider.storage.eu-north1.nebius.cloud/nebius/nebius"
      version = ">= 0.5.55"
    }
  }
}

provider "nebius" {
}
variable "parent_id" {
  description = "Nebius parent ID (e.g. project ID) where the controller will be created"
  type        = string
}

variable "region" {
  description = "Nebius region where the controller will be created"
  type        = string
  default     = "us-central1"
}

variable "subnet_id" {
  description = "Nebius subnet ID where the controller will be created"
  type        = string
}

variable "admin_ssh_keys" {
  description = "SSH public keys to add to the controller for admin access"
  type        = string
}

variable "sa_editor_group_id" {
  description = "Service account editor group ID for the controller"
  type        = string
}


module "config" {
  source = "../../shared/configs_full"

  name               = "velda-oss"
  controller_version = "v1.1.2"
  admin_ssh_keys     = var.admin_ssh_keys
  zfs_disks          = ["/dev/disk/by-id/virtio-data-disk"]

  extra_config = {
    provisioners = [
      {
        nebius_auto = {
          parent_id     = var.parent_id
          subnet_id     = var.subnet_id
          admin_ssh_key = var.admin_ssh_keys
          autoscaler_config = {
            max_agents         = 5
            min_idle_agents    = 0
            max_idle_agents    = 2
            idle_decay         = "180s"
            initial_delay      = "30s"
            sync_loop_interval = "60s"
            metadata = {
              description = "Nebius auto-scaled agents"
            }
          }
          pool_details = [{
            pool_name       = "shell"
            platform        = "cpu-d3"
            resource_preset = "4vcpu-16gb"
            description     = "Nebius 4-vcpu, 16 GB RAM instances"
            }, {
            pool_name       = "gpu-h200-1"
            platform        = "gpu-h200-sxm"
            resource_preset = "1gpu-16vcpu-200gb"
            description     = "Nebius 1-H200 GPU, 16 vCPU, 200 GB RAM instances"
            }
          ]
        }
      }
    ]
  }
}

module "controller" {
  source = "../controller"

  name       = "velda-oss"
  cloud_init = module.config.cloud_init

  sa_member_group = var.sa_editor_group_id

  region    = var.region
  parent_id = var.parent_id
  subnet_id = var.subnet_id

  data_disk_size = 100
}
