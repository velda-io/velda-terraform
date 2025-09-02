locals {
  pool_config = {
    name = var.pool,
    auto_scaler = merge(
      var.autoscale_config,
      {
        backend = {
          aws_launch_template = {
            region                  = var.controller_output.region
            launch_template_name    = "${var.controller_output.name}-agent-${var.pool}"
            use_instance_id_as_name = true
          }
        }
      }
    )
  }
}

resource "aws_ssm_parameter" "agent_config" {
  name  = "/${var.controller_output.name}/pools/${var.pool}"
  type  = "String"
  value = yamlencode(local.pool_config)
}
