output "agent_configs" {
  value = {
    name = var.name

    region             = var.region
    zone               = var.zone
    vpc_id             = var.vpc_id
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.agent_sg.id]
    controller_ip      = aws_instance.controller.private_ip
    instance_profile   = var.agent_role_override != null ? aws_iam_instance_profile.agent_profile[0].name : ""
    use_nat            = local.use_nat
    agent_version      = var.controller_version
  }
}
