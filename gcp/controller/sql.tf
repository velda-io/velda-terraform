locals {
  db_cnt = var.enterprise_config == null ? 0 : var.enterprise_config.sql_db == null ? 1 : 0
}
resource "random_password" "db_password" {
  count   = local.db_cnt
  length  = 16
  special = false
}

resource "google_sql_database_instance" "postgres_instance" {
  count            = local.db_cnt
  name             = "${var.name}-pg-instance"
  database_version = "POSTGRES_17"
  region           = local.region

  settings {
    edition           = "ENTERPRISE"
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false # Disables public IP
      private_network = local.network
    }

    location_preference {
      zone = var.zone
    }
  }
}

resource "google_sql_database" "db" {
  count    = local.db_cnt
  name     = "velda_db"
  instance = google_sql_database_instance.postgres_instance[0].name
}

resource "google_sql_user" "db_user" {
  count    = local.db_cnt
  name     = "velda_user"
  instance = google_sql_database_instance.postgres_instance[0].name
  password = random_password.db_password[0].result
}

locals {
  postgres_url = var.enterprise_config == null ? "" : var.enterprise_config.sql_db == null ? "postgres://${google_sql_user.db_user[0].name}:${random_password.db_password[0].result}@${google_sql_database_instance.postgres_instance[0].private_ip_address}/${google_sql_database.db[0].name}" : var.enterprise_config.sql_db
}
