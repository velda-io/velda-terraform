resource "aws_iam_role" "controller_role" {
  name = "${var.name}-controller-role"

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

resource "aws_iam_policy" "controller_policy" {
  name        = "${var.name}-SSMS3Policy"
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
          "arn:aws:ssm:${var.region}:*:parameter/${var.name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParametersByPath"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:*:parameter/${var.name}/pools/"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:${var.name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeLaunchTemplates"
        ],
        Resource = "*",
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:RunInstances",
          "ec2:CreateTags"
        ],
        Resource = "*",
        Condition = {
          ArnEquals = {
            "ec2:LaunchTemplate" : "arn:aws:ec2:${var.region}:*:launch-template/*",
          }
          Bool = {
            "ec2:IsLaunchTemplateResource" : "true"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateTags",
          "ec2:DescribeInstances",
        ],
        Resource = "*",
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:TerminateInstances",
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/VeldaApp" = "${var.name}"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          local.agent_role_arn,
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

resource "aws_iam_role_policy_attachment" "controller_policy_attachment" {
  role       = aws_iam_role.controller_role.name
  policy_arn = aws_iam_policy.controller_policy.arn
}
