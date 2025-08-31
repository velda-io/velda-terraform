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
    domain      = string,
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