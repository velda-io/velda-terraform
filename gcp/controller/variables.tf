variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "zone" {
  description = "The zone of the deployment."
  type        = string
}

variable "subnetwork" {
  description = "sub-network for the deployment"
  type        = string
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "e2-micro"
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "pd-ssd"
}

variable "data_disk_size" {
  description = "Size of disk for user data"
  type        = number
  default     = 100
}

variable "use_nat_gateway" {
  description = "Use NAT in the network. Setting it to false will allocate public IPs for the controller and agents."
  type        = bool
  default     = false
}

variable "external_access" {
  description = "Options for public IP access. Default to disallow"
  type = object({
    server_ip_address     = optional(string, null), // If not set, default to ephermeral public IP.
    network_tier          = optional(string, "PREMIUM")
    use_proxy             = optional(bool, false)                 // Whether the client should use a proxy to connect to the agent.
    allowed_source_ranges = optional(list(string), ["0.0.0.0/0"]) // Source ranges for the firewall rule
    allowed_source_tags   = optional(list(string), [])            // Source tags for the firewall rule
    setup_firewall_rule   = optional(bool, true)                  // Whether to setup firewall rule for the external access
  })
  default = {}
}

variable "controller_image_version" {
  description = "value of the controller image to use. Default to the latest version."
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Enable monitoring for the deployment."
  type        = bool
  default     = false
}

variable "extra_provisioners" {
  description = "Additional provisioners to add to the controller config."
  type        = list(any)
  default     = []
}

variable "controller_version" {
  description = "The version of Velda controller to install."
  type        = string
  default     = "latest"
}

variable "default_agent_version" {
  description = "The default version of Velda agent to use."
  type        = string
  default     = null
}

variable "enterprise_config" {
  description = "Configs for enterprise features. The image must also use enterprise editions."
  type = object({
    domain = string
    sql_db = optional(string)
    https_certs = optional(object({
      cert = string
      key  = string
    }))
    organization = string
  })
  default = null
}

variable "extra_config" {
  description = "Extra configuration to add to the controller config."
  type        = any
  default     = {}
}