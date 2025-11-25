resource "random_password" "postgres" {
  count   = var.postgres_url == null ? 1 : 0
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

locals {
  postgres_url = var.postgres_url != null ? var.postgres_url : "postgres://postgres:${random_password.postgres[0].result}@localhost:5432/postgres?sslmode=disable"
}
