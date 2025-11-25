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
