locals {
  https_enabled = var.enterprise_config != null ? var.enterprise_config.https_certs != null : false
}
resource "aws_secretsmanager_secret" "certs_csr" {
  count = local.https_enabled ? 1 : 0
  name  = "${var.name}/certs-csr"
}

resource "aws_secretsmanager_secret_version" "cert_csr_value" {
  count         = local.https_enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.certs_csr[0].id
  secret_string = var.enterprise_config.https_certs.cert
}

resource "aws_secretsmanager_secret" "certs_key" {
  count = local.https_enabled ? 1 : 0
  name  = "${var.name}/certs-key"
}

resource "aws_secretsmanager_secret_version" "cert_key_value" {
  count         = local.https_enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.certs_key[0].id
  secret_string = var.enterprise_config.https_certs.key
}