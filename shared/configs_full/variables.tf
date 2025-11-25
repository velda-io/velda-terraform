variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "enterprise_config" {
  description = "Configs for enterprise features. The image must also use enterprise editions."
  type = object({
    domain = string
    jump_server_addr = optional(string)
    sql_db = optional(string)
    https_certs = optional(object({
      cert = string
      key  = string
    }))
    organization = string
  })
  default = null
}

variable "extra_provisioners" {
  description = "Additional provisioners to add to the controller config"
  type        = list(any)
  default     = []
}

variable "use_proxy" {
  description = "Use proxy server to access agents"
  type        = bool
  default     = false
}

variable "postgres_url" {
  description = "The PostgresSQL instance URL."
  type        = string
  sensitive   = true
  default     = null
}

variable "extra_config" {
  description = "Extra configuration to add to the controller config"
  type        = any
  default     = {}
}

variable "admin_ssh_keys" {
  description = "List of admin SSH public keys to add to the controller"
  type        = string
}

variable "controller_version" {
  description = "Version of Velda controller to install"
  type        = string
}

variable "base_instance_images" {
  description = "List of base instance images."
  type = list(object({
    name        = string
    docker_name = string
  }))
  default = [
    {
      name        = "ubuntu-24.04"
      docker_name = "veldaio/base-ubuntu:24.04"
    },
    {
      name        = "ubuntu-22.04"
      docker_name = "veldaio/base-ubuntu:22.04"
    }
  ]
}

variable "zfs_disks" {
  description = "List of disks to use for zfs pool."
  type        = list(string)
}

variable "extra_cloud_init" {
  description = "Additional packages to install via cloud-init"
  type = object({
    packages = optional(list(string), [])
    write_files = optional(list(object({
      path        = string
      content     = string
      permissions = optional(string)
      owner       = optional(string)
    })), [])
    runcmd = optional(list(string), [])
  })
  default = {}
}
