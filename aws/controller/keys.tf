resource "tls_private_key" "auth_token_key" {
  count       = local.enable_enterprise ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P256" # This corresponds to prime256v1 (secp256r1)
}

resource "aws_secretsmanager_secret" "auth_token_public_key" {
  count = local.enable_enterprise ? 1 : 0
  name  = "${var.name}/auth-public-key"
}

resource "aws_secretsmanager_secret_version" "auth_token_public_value" {
  count         = local.enable_enterprise ? 1 : 0
  secret_id     = aws_secretsmanager_secret.auth_token_public_key[0].id
  secret_string = tls_private_key.auth_token_key[0].public_key_pem
}

resource "aws_secretsmanager_secret" "auth_token_private_key" {
  count = local.enable_enterprise ? 1 : 0
  name  = "${var.name}/auth-private-key"
}

resource "aws_secretsmanager_secret_version" "auth_token_private_value" {
  count         = local.enable_enterprise ? 1 : 0
  secret_id     = aws_secretsmanager_secret.auth_token_private_key[0].id
  secret_string = tls_private_key.auth_token_key[0].private_key_pem
}

locals {
  use_proxy = var.enterprise_config == null ? false : var.external_access.use_proxy
}
resource "tls_private_key" "jumphost_key" {
  count     = local.use_proxy ? 1 : 0
  algorithm = "ED25519"
}

resource "aws_secretsmanager_secret" "jumphosts_public_key" {
  count = local.use_proxy ? 1 : 0
  name  = "${var.name}/jumphost-public"
}

resource "aws_secretsmanager_secret_version" "jumphost_public_value" {
  count         = local.use_proxy ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jumphosts_public_key[0].id
  secret_string = tls_private_key.jumphost_key[0].public_key_openssh
}

resource "aws_secretsmanager_secret" "jumphosts_private_key" {
  count = local.use_proxy ? 1 : 0
  name  = "${var.name}/jumphost-private"
}

resource "aws_secretsmanager_secret_version" "jumphost_private_value" {
  count         = local.use_proxy ? 1 : 0
  secret_id     = aws_secretsmanager_secret.jumphosts_private_key[0].id
  secret_string = tls_private_key.jumphost_key[0].private_key_pem
}

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

resource "aws_secretsmanager_secret" "saml_sp_public_key" {
  count = local.enable_enterprise ? 1 : 0
  name  = "${var.name}/saml-sp-public-key"
}

resource "aws_secretsmanager_secret_version" "saml_sp_public_value" {
  count         = local.enable_enterprise ? 1 : 0
  secret_id     = aws_secretsmanager_secret.saml_sp_public_key[0].id
  secret_string = tls_self_signed_cert.sp[0].cert_pem
}

resource "aws_secretsmanager_secret" "saml_sp_private_key" {
  count = local.enable_enterprise ? 1 : 0
  name  = "${var.name}/saml-sp-private-key"
}

resource "aws_secretsmanager_secret_version" "saml_sp_private_value" {
  count         = local.enable_enterprise ? 1 : 0
  secret_id     = aws_secretsmanager_secret.saml_sp_private_key[0].id
  secret_string = tls_private_key.saml_sp_key[0].private_key_pem
}
