data "aws_iam_role" "agent_role" {
  count = var.agent_role_override != null ? 1 : 0
  name  = var.agent_role_override
}

resource "aws_iam_role" "agent_role" {
  count = var.agent_role_override == null ? 1 : 0
  name = "${var.name}-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

locals {
  agent_role_name = var.agent_role_override != null ? data.aws_iam_role.agent_role[0].name : aws_iam_role.agent_role[0].name
  agent_role_arn  = var.agent_role_override != null ? data.aws_iam_role.agent_role[0].arn : aws_iam_role.agent_role[0].arn
}

resource "aws_iam_policy" "agent_policy" {
  name        = "${var.name}-agent"
  description = "Policy to allow EC2 instance to read from SSM and S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:*:parameter/${var.name}/agent/*"
        ]
      },
         {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:*:parameter/${var.name}/agent-config/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "ec2:DescribeTags",
        Resource = "*",
        /*
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/InstanceId" = "$${ec2:InstanceId}"
          }
        }*/
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances"
        ],
        Resource = "*",
        /*
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Name" = "${var.name}"
          }
        }*/
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:${var.name}/auth-public-key-*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
        ],
        Resource = [
          "arn:aws:s3:::velda-release/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_policy_attachment" {
  role       = local.agent_role_name
  policy_arn = aws_iam_policy.agent_policy.arn
}

resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.name}-agent-profile"
  role = local.agent_role_name
}