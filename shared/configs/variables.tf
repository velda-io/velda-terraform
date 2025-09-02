variable "name" {
  description = "Name of the deployment"
  type        = string
}

variable "postgres_url" {
  description = "The PostgresSQL instance URL."
  type        = string
  sensitive   = true
}

variable "enterprise_config" {
  description = "Enterprise configuration"
  type = object({
    domain = string,
    https_certs = optional(object({
      cert = string,
      key  = string,
    }))
  })
}

variable "use_proxy" {
  description = "Use proxy server to access agents"
  type        = bool
  default     = false
}

variable "provisioners" {
  description = "Provisioners to add to the controller config."
  type        = any
  default     = []
}

variable "zfs_disks" {
  description = "List of disks to use for zfs pool."
  type        = list(string)
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
      docker_name = "veldaio/base:24.04"
    },
    {
      name        = "ubuntu-22.04"
      docker_name = "veldaio/base-ubuntu-x86:22.04"
    }
  ]
}