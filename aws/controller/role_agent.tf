data "aws_iam_role" "agent_role" {
  count = var.agent_role_override != null ? 1 : 0
  name  = var.agent_role_override
}

locals {
  agent_role_name = var.agent_role_override != null ? data.aws_iam_role.agent_role[0].name : null
  agent_role_arn  = var.agent_role_override != null ? data.aws_iam_role.agent_role[0].arn : null
}

resource "aws_iam_instance_profile" "agent_profile" {
  count = var.agent_role_override != null ? 1 : 0
  name  = "${var.name}-agent-profile"
  role  = local.agent_role_name
}