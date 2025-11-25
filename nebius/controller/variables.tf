variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "velda"
}

variable "region" {
  description = "The region of the deployment"
  type        = string
}

variable "parent_id" {
  description = "Parent project ID for Nebius resources"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the deployment"
  type        = string
}

variable "controller_platform" {
  description = "Platform type for controller instance (e.g., cpu-d3)"
  type        = string
  default     = "cpu-d3"
}

variable "controller_preset" {
  description = "Preset configuration for controller instance (e.g., 4vcpu-16gb)"
  type        = string
  default     = "4vcpu-16gb"
}

variable "data_disk_size" {
  description = "Size of disk for user data in GB"
  type        = number
  default     = 20
}

variable "data_disk_type" {
  description = "Type of the disk for storing user data"
  type        = string
  default     = "NETWORK_SSD"
}

variable "cloud_init" {
    description = "Cloud-init configuration for the controller. Use config_full module to generate one."
    type        = string
}

variable "sa_member_group" {
  description = "IAM group for the controller service account"
  type        = string
}

variable "network_interface" {
  description = "Additional network interfaces to attach to the controller instance"
  type        = list(object({
    name               = string
    subnet_id          = string
    ip_address         = object({ allocation_id = string })
    public_ip_address  = optional(object({ allocation_id = string }), null)
  }))
}