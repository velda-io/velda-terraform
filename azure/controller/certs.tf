locals {
  https_enabled = var.enterprise_config != null ? var.enterprise_config.https_certs != null : false
}

resource "azurerm_key_vault_secret" "cert_csr" {
  count        = local.https_enabled ? 1 : 0
  name         = "certs-csr"
  value        = var.enterprise_config.https_certs.cert
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

resource "azurerm_key_vault_secret" "cert_key" {
  count        = local.https_enabled ? 1 : 0
  name         = "certs-key"
  value        = var.enterprise_config.https_certs.key
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}
