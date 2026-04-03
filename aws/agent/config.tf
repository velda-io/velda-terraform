locals {
  pool_config = {
    name = var.pool,
    auto_scaler = merge(
      var.autoscale_config,
      {
        backend = {
          aws_launch_template = merge({
            region                  = var.controller_output.region
            launch_template_name    = "${var.controller_output.name}-agent-${var.pool}"
            use_instance_id_as_name = true
            },
            var.agent_ami == "aws-ml" ? {
              ami_id = "aws-ml"
              agent_config = {
                sandbox_config = var.sandbox_config
                daemon_config  = var.daemon_config
              }
            } : null,
            var.max_stopped_instance > 0 ? {
              max_stopped_instances = var.max_stopped_instance
            } : null
          )
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
