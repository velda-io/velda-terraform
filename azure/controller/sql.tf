locals {
  db_cnt = var.enterprise_config == null ? 0 : var.enterprise_config.sql_db == null ? 1 : 0
}

resource "random_password" "db_password" {
  count   = local.db_cnt
  length  = 16
  special = false
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  count               = local.db_cnt
  name                = "${var.name}-postgres"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = "velda"
  administrator_password = random_password.db_password[0].result

  sku_name   = "B_Standard_B1ms"
  version    = "16"
  storage_mb = 32768

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = var.subnet_id
  zone                = "1"

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "velda_db" {
  count     = local.db_cnt
  name      = "velda"
  server_id = azurerm_postgresql_flexible_server.postgres[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "controller_access" {
  count            = local.db_cnt
  name             = "controller-access"
  server_id        = azurerm_postgresql_flexible_server.postgres[0].id
  start_ip_address = azurerm_network_interface.controller_nic.private_ip_address
  end_ip_address   = azurerm_network_interface.controller_nic.private_ip_address
}

locals {
  postgres_url = var.enterprise_config == null ? "" : var.enterprise_config.sql_db == null ? "postgres://${azurerm_postgresql_flexible_server.postgres[0].administrator_login}:${random_password.db_password[0].result}@${azurerm_postgresql_flexible_server.postgres[0].fqdn}/${azurerm_postgresql_flexible_server_database.velda_db[0].name}" : var.enterprise_config.sql_db
}
