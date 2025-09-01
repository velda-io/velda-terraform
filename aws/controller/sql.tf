locals {
  db_cnt = var.enterprise_config == null ? 0 : var.enterprise_config.sql_db == null ? 1 : 0
}
resource "random_password" "db_password" {
  count   = local.db_cnt
  length  = 16
  special = false
}

resource "aws_db_instance" "postgres_instance" {
  count                  = local.db_cnt
  identifier             = "${var.name}-pg-instance"
  db_name                = "velda"
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "velda"
  availability_zone      = var.zone
  password               = random_password.db_password[0].result
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

resource "aws_db_subnet_group" "default" {
  name_prefix = "${var.name}-db-subnet-group"
  subnet_ids  = var.subnet_ids
}

resource "aws_security_group" "db_sg" {
  name        = "${var.name}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.controller_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  postgres_url = var.enterprise_config == null ? "" : var.enterprise_config.sql_db == null ? "postgres://${aws_db_instance.postgres_instance[0].username}:${random_password.db_password[0].result}@${aws_db_instance.postgres_instance[0].address}/${aws_db_instance.postgres_instance[0].db_name}" : var.enterprise_config.sql_db
}
