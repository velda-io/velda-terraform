locals {
  public_address_protocol = var.enterprise_config != null ? var.enterprise_config.https_certs != null ? "https" : "http" : null
}
output "agent_configs" {
  value = {
    name = var.name

    region             = var.region
    zone               = var.zone
    vpc_id             = var.vpc_id
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.agent_sg.id]
    broker_info = {
      address        = "${aws_instance.controller.private_ip}:50051"
      public_address = var.enterprise_config != null ? "${local.public_address_protocol}://${var.enterprise_config.domain}" : ""
    }
    controller_ip    = aws_instance.controller.private_ip
    instance_profile = var.agent_role_override != null ? aws_iam_instance_profile.agent_profile[0].name : ""
    use_nat          = local.use_nat
    agent_version    = var.controller_version
  }
}

output "postgres_url" {
  description = "PostgreSQL connection URL"
  value       = local.postgres_url
  sensitive   = true
}

output "db_security_group_arn" {
  description = "ARN of the database security group"
  value       = local.db_cnt == 0 ? null : aws_security_group.db_sg[0].id
}

output "controller_instance_id" {
  description = "ID of the controller instance"
  value       = aws_instance.controller.id
}

output "controller_network_interface_id" {
  description = "Primary network interface ID of the controller instance"
  value       = aws_instance.controller.primary_network_interface_id
}


output "controller_public_ip" {
  description = "Public IP address of the controller instance (if assigned)"
  value       = var.external_access.use_eip ? aws_eip.lb[0].public_ip : aws_instance.controller.public_ip
}

output "controller_security_group_id" {
  description = "ID of the controller security group"
  value       = aws_security_group.controller_sg.id
}

output "agent_security_group_id" {
  description = "ID of the agent security group"
  value       = aws_security_group.agent_sg.id
}