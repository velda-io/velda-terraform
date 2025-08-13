variable "controller_output" {
  description = "The output of the controller module for agent"
  type = object({
    name               = string
    region             = string
    zone               = string
    vpc_id             = string
    subnet_ids         = list(string)
    security_group_ids = list(string)
    controller_ip      = string
    instance_profile   = string
    use_nat            = bool
  })
}

variable "instance_type" {
  description = "The instance type for the agent"
  type        = string
  default     = "t2.micro"
}

variable "agent_ami" {
  description = "The AMI for the agent"
  type        = string
  default     = "ami-09eeb480639b7ca17"
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
  default = null
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
