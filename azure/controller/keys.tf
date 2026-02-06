resource "azurerm_key_vault" "velda_kv" {
  count                      = local.enable_enterprise ? 1 : 0
  name                       = "${var.name}-kv-${substr(md5(var.resource_group_name), 0, 8)}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.controller_identity.principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

# Auth Token Keys
resource "tls_private_key" "auth_token_key" {
  count       = local.enable_enterprise ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "azurerm_key_vault_secret" "auth_public_key" {
  count        = local.enable_enterprise ? 1 : 0
  name         = "auth-public-key"
  value        = tls_private_key.auth_token_key[0].public_key_pem
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

resource "azurerm_key_vault_secret" "auth_private_key" {
  count        = local.enable_enterprise ? 1 : 0
  name         = "auth-private-key"
  value        = tls_private_key.auth_token_key[0].private_key_pem
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

# Jumphost Keys
locals {
  use_proxy = var.enterprise_config == null ? false : var.external_access.use_proxy
}

resource "tls_private_key" "jumphost_key" {
  count     = local.use_proxy ? 1 : 0
  algorithm = "ED25519"
}

resource "azurerm_key_vault_secret" "jumphost_public_key" {
  count        = local.use_proxy ? 1 : 0
  name         = "jumphost-public"
  value        = tls_private_key.jumphost_key[0].public_key_openssh
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

resource "azurerm_key_vault_secret" "jumphost_private_key" {
  count        = local.use_proxy ? 1 : 0
  name         = "jumphost-private"
  value        = tls_private_key.jumphost_key[0].private_key_pem
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

# SAML Service Provider Keys
resource "tls_private_key" "saml_sp_key" {
  count     = local.enable_enterprise ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "sp" {
  count           = local.enable_enterprise ? 1 : 0
  private_key_pem = tls_private_key.saml_sp_key[0].private_key_pem

  subject {
    common_name  = var.enterprise_config.domain
    organization = var.enterprise_config.organization
  }

  validity_period_hours = 87600 # 10 years
  early_renewal_hours   = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
  ]

  is_ca_certificate = false
}

resource "azurerm_key_vault_secret" "saml_sp_public_key" {
  count        = local.enable_enterprise ? 1 : 0
  name         = "saml-sp-public-key"
  value        = tls_self_signed_cert.sp[0].cert_pem
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}

resource "azurerm_key_vault_secret" "saml_sp_private_key" {
  count        = local.enable_enterprise ? 1 : 0
  name         = "saml-sp-private-key"
  value        = tls_private_key.saml_sp_key[0].private_key_pem
  key_vault_id = azurerm_key_vault.velda_kv[0].id

  depends_on = [azurerm_key_vault.velda_kv]
}
