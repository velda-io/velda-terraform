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
  description = "Options for public IP access."
  type = object({
    network_tier = optional(string, "PREMIUM")
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

variable "version" {
  description = "The version of Velda to install. If not set, the latest version will be installed."
  type        = string
  default     = "latest"
}