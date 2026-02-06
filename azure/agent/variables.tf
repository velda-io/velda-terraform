variable "controller_output" {
  description = "The output of the controller module for agent"
  type = object({
    name                          = string
    subscription_id               = string
    location                      = string
    resource_group                = string
    vnet_name                     = string
    subnet_id                     = string
    security_group_id             = string
    application_security_group_id = string
    broker_info = object({
      address        = string
      public_address = optional(string)
    })
    managed_identity_id  = string
    use_nat              = bool
    agent_version        = string
    app_configuration_id = string
  })
}

variable "vm_size" {
  description = "The VM size for the agent"
  type        = string
  default     = "Standard_B2s"
}

variable "agent_image_id" {
  description = "The image ID for the agent. Default to be determined by version."
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

variable "init_script_content" {
  description = "The initialization script for the agent"
  type        = string
  default     = null
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

variable "agent_version" {
  description = "The version of the Velda agent. Default to use Controller version."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Admin username for the agent VMs"
  type        = string
  default     = "velda-admin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the agent VMs"
  type        = string
}
