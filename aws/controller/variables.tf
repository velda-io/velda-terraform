variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "region" {
  description = "The region of the deployment"
  type        = string
}

variable "zone" {
  description = "The zone of the deployment. Must be within the region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the deployment"
  type        = string
}

variable "subnet_ids" {
  description = "sub-network for the deployment"
  type        = list(string)
}

variable "controller_machine_type" {
  description = "Machine type of controller instance"
  type        = string
  default     = "t2.micro"
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "gp3"
}

variable "data_disk_size" {
  description = "Size of disk for user data"
  type        = number
  default     = 20
}

variable "controller_subnet_id" {
  description = "Controller subnet"
  type        = string
}

variable "controller_ami" {
  description = "Controller AMI"
  type        = string
  default     = null
}

variable "agent_role_override" {
  description = "Override the agent role. If not set, will use a minimal permission agent role."
  type        = string
  default     = null
}
variable "extra_provisioners" {
  description = "Additional provisioners to add to the controller config."
  type        = list(any)
  default     = []
}

variable "controller_version" {
  description = "The version of Velda controller to install."
  type        = string
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

variable "external_access" {
  description = "Optionsl for public IP access. Default to disallow"
  type = object({
    use_proxy                  = optional(bool, false),
    ip_address                 = optional(string, null), // If not set, default to ephermeral public IP.
    use_eip                    = optional(bool, false),  // Whether to use EIP for the controller.
    use_nat                    = optional(bool, false),  // Whether to use NAT in the network.
    use_controller_external_ip = optional(bool, false),  // Whether controller has external IP.
  })
  default = {}
}

variable "connection_source" {
  description = "Source of connection to the controller"
  type = list(object({
    cidr_ipv4                    = optional(string),
    cidr_ipv6                    = optional(string),
    prefix_list_id               = optional(string),
    referenced_security_group_id = optional(string),
  }))
}