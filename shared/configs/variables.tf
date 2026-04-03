variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "enterprise_config" {
  description = "Configs for enterprise features. The image must also use enterprise editions."
  type = object({
    domain           = string
    jump_server_addr = optional(string)
    sql_db           = optional(string)
    app_domain       = optional(string)
    https_certs = optional(object({
      cert = string
      key  = string
    }))
    organization = optional(string)
  })
  default = null
}

variable "provisioners" {
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
  type        = list(string)
}

variable "access_ssh_keys" {
  description = "SSH public keys to access Velda instances"
  type        = list(string)
  default     = null
}

variable "controller_version" {
  description = "Version of Velda controller to install"
  type        = string
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

variable "config_base_path" {
  description = "Path to the base configuration file for the controller"
  type        = string
  default     = "/etc/velda"
}