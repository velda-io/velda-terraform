variable "controller_output" {
  description = "The output of the controller module for agent"
  type = object({
    project               = string
    name                  = string
    zone                  = string
    subnetwork            = string
    broker_info = object({
      address        = string
      public_address = optional(string)
    })
    agent_service_account = string
    use_nat_gateway       = bool
    config_gcs_bucket     = string
    config_gcs_prefix     = string
    default_agent_version = string
  })
}

variable "instance_type" {
  description = "The instance type for the agent"
  type        = string
  default     = "n1-standard-1"
}

variable "agent_image_version" {
  description = "The image for the agent"
  type        = string
  default     = null
}

variable "pool" {
  description = "The agent pool name"
  type        = string
}

variable "autoscale_config" {
  description = "The autoscale configuration"
  // See proto of AgentPool_AutoScaler
  type = any
}

variable "accelerator_type" {
  description = "The type of accelerator to attach to the agent instances"
  type        = string
  default     = null
}

variable "accelerator_count" {
  description = "The number of accelerators to attach to the agent instances"
  type        = number
  default     = 0
}

variable "sandbox_config" {
  description = "Option of sandbox. See proto of SandboxConfig for details"
  type        = any
  default     = {}
}

variable "daemon_config" {
  description = "Configuration for the Velda agent daemon"
  type        = any
  default     = {}
}

variable "upgrade_agent_on_start" {
  description = "gs:// URL to override the agent version and override the agent installed"
  type        = string
  default     = null
}

variable "localssd_count" {
  description = "Number of local SSDs to attach to each agent instance"
  type        = number
  default     = 0
}

variable "preemptible" {
  description = "Whether to use preemptible instances for the agents"
  type        = bool
  default     = false
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB for agent instances"
  type        = number
  default     = 10
}

variable "boot_disk_type" {
  description = "Boot disk type for agent instances (e.g. pd-standard, pd-ssd)"
  type        = string
  default     = "pd-standard"
}