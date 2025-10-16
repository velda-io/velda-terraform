resource "tls_private_key" "auth_token_key" {
  count = local.enable_enterprise ? 1 : 0

  algorithm   = "ECDSA"
  ecdsa_curve = "P256" # This corresponds to prime256v1 (secp256r1)
}

resource "tls_private_key" "jumphost_key" {
  count     = local.use_proxy ? 1 : 0
  algorithm = "ED25519"
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

resource "google_secret_manager_secret" "jumphosts_public_key" {
  count     = local.use_proxy ? 1 : 0
  project   = var.project
  secret_id = "${var.name}-jumphost-public"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "jumphost_public_value" {
  count       = local.use_proxy ? 1 : 0
  secret      = google_secret_manager_secret.jumphosts_public_key[0].id
  secret_data = tls_private_key.jumphost_key[0].public_key_openssh
}

resource "google_secret_manager_secret_iam_member" "jumphost_public_access" {
  count     = local.use_proxy ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.jumphosts_public_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "jumphosts_private_key" {
  count = local.use_proxy ? 1 : 0

  project   = var.project
  secret_id = "${var.name}-jumphost-private"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

locals {
  use_proxy = var.enterprise_config == null ? false : var.external_access.use_proxy
}
resource "google_secret_manager_secret_version" "jumphost_private_value" {
  count       = local.use_proxy ? 1 : 0
  secret      = google_secret_manager_secret.jumphosts_private_key[0].id
  secret_data = tls_private_key.jumphost_key[0].private_key_pem
}

resource "google_secret_manager_secret_iam_member" "jumphost_private_access" {
  count     = local.use_proxy ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.jumphosts_private_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "auth_public_key" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = "${var.name}-auth-public-key"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "auth_public_key" {
  count       = local.enable_enterprise ? 1 : 0
  secret      = google_secret_manager_secret.auth_public_key[0].id
  secret_data = tls_private_key.auth_token_key[0].public_key_pem
}

resource "google_secret_manager_secret" "auth_private_key" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = "${var.name}-auth-private-key"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "auth_private_key" {
  count       = local.enable_enterprise ? 1 : 0
  secret      = google_secret_manager_secret.auth_private_key[0].id
  secret_data = tls_private_key.auth_token_key[0].private_key_pem
}

resource "google_secret_manager_secret_iam_member" "auth_public_key_access" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.auth_public_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "auth_private_key_access" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.auth_private_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "saml_sp_public_key" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = "${var.name}-saml-sp-public-key"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "saml_sp_public_key" {
  count       = local.enable_enterprise ? 1 : 0
  secret      = google_secret_manager_secret.saml_sp_public_key[0].id
  secret_data = tls_self_signed_cert.sp[0].cert_pem
}

resource "google_secret_manager_secret" "saml_sp_private_key" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = "${var.name}-saml-sp-private-key"
  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "saml_sp_private_key" {
  count       = local.enable_enterprise ? 1 : 0
  secret      = google_secret_manager_secret.saml_sp_private_key[0].id
  secret_data = tls_private_key.saml_sp_key[0].private_key_pem
}
resource "google_secret_manager_secret_iam_member" "saml_sp_public_access" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.saml_sp_public_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "saml_sp_private_access" {
  count     = local.enable_enterprise ? 1 : 0
  project   = var.project
  secret_id = google_secret_manager_secret.saml_sp_private_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}