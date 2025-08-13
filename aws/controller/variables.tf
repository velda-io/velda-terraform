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

variable "use_nat" {
  description = "Use NAT in the network. Setting it to false will allocate public IPs for the controller and agents."
  type        = bool
  default     = false
}