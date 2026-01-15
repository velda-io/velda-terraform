resource "aws_security_group" "controller_sg" {
  name   = "${var.name}-controller"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "http_ingress" {
  for_each                     = { for k, v in var.connection_source : k => v }
  description                  = "http"
  security_group_id            = aws_security_group.controller_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_ingress_rule" "https_ingress" {
  for_each                     = { for k, v in var.connection_source : k => v }
  description                  = "https"
  security_group_id            = aws_security_group.controller_sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_ingress_rule" "custom_port_ingress" {
  for_each                     = { for k, v in var.connection_source : k => v }
  description                  = "agent ssh"
  security_group_id            = aws_security_group.controller_sg.id
  from_port                    = 2222
  to_port                      = 2222
  ip_protocol                  = "tcp"
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_ingress_rule" "jump_proxy_ssh_ingress" {
  for_each                     = { for k, v in var.connection_source : k => v }
  description                  = "Jump-proxy via SSH"
  security_group_id            = aws_security_group.controller_sg.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_ingress_rule" "grpc_ingress" {
  for_each                     = { for k, v in var.connection_source : k => v }
  description                  = "grpc"
  security_group_id            = aws_security_group.controller_sg.id
  from_port                    = 50051
  to_port                      = 50051
  ip_protocol                  = "tcp"
  cidr_ipv4                    = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6                    = lookup(each.value, "cidr_ipv6", null)
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)
}

resource "aws_vpc_security_group_ingress_rule" "agent_ingress" {
  security_group_id            = aws_security_group.controller_sg.id
  description                  = "NFS from_agent"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.agent_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "fileserver_ingress" {
  security_group_id            = aws_security_group.controller_sg.id
  description                  = "file service from_agent"
  from_port                    = 7655
  to_port                      = 7655
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.agent_sg.id
}

data "aws_ec2_managed_prefix_list" "ec2_instance_connect" {
  name = "com.amazonaws.${var.region}.ec2-instance-connect"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.controller_sg.id
  description       = "ssh-from-ec2-instance-connect"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.ec2_instance_connect.id
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.controller_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "agent_sg" {
  name   = "${var.name}-agent"
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress_agent" {
  security_group_id = aws_security_group.agent_sg.id
  description       = "ssh-from-ec2-instance-connect"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.ec2_instance_connect.id
}

resource "aws_vpc_security_group_ingress_rule" "controller_ingress_agent" {
  security_group_id            = aws_security_group.agent_sg.id
  description                  = "from-controller"
  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.controller_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "between_agents" {
  security_group_id            = aws_security_group.agent_sg.id
  description                  = "from-agents"
  from_port                    = -1
  to_port                      = -1
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.agent_sg.id
}

resource "aws_vpc_security_group_egress_rule" "all_egress_agent" {
  security_group_id = aws_security_group.agent_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
