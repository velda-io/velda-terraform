variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for the deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the deployment"
  type        = string
}

variable "controller_subnet_id" {
  description = "Controller subnet ID"
  type        = string
}

variable "controller_vm_size" {
  description = "VM size for controller instance"
  type        = string
  default     = "Standard_D2as_v7"
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "Premium_LRS"
}

variable "data_disk_size" {
  description = "Size of disk for user data in GB"
  type        = number
  default     = 20
}

variable "controller_image" {
  description = "Controller VM image reference"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = null
}

variable "agent_identity_override" {
  description = "Override the agent managed identity. If not set, will create a new managed identity."
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
    app_domain   = optional(string)
  })
  default = null
}

variable "external_access" {
  description = "Optional for public IP access. Default to disallow"
  type = object({
    use_proxy                  = optional(bool, false)
    allow_direct_api_access    = optional(bool, false)
    use_nat_gateway            = optional(bool, false)
    use_controller_external_ip = optional(bool, false)
  })
  default = {}
}

variable "connection_source" {
  description = "Source IP ranges for connections to the controller"
  type        = list(string)
  default     = ["*"]
}

variable "extra_config" {
  description = "Extra configuration to add to the controller config."
  type        = any
  default     = {}
}

variable "additional_controller_nsg_ids" {
  description = "Additional network security group IDs to attach to the controller NIC."
  type        = list(string)
  default     = []
}

variable "access_public_keyss" {
  description = "A list of SSH public keys to access controller only for network access."
  type        = list(string)
  default     = []
}

variable "controller_ssh_public_key" {
  description = "Optional controller SSH public key in OpenSSH format. If null, a keypair will be generated."
  type        = string
  default     = null
}
