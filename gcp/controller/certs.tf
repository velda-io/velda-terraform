locals {
  https_enabled = var.enterprise_config != null ? var.enterprise_config.https_certs != null : false
}
resource "google_secret_manager_secret" "certs_csr" {
  count     = local.https_enabled ? 1 : 0
  secret_id = "${var.name}-certs-csr"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "cert_csr_value" {
  count       = local.https_enabled ? 1 : 0
  secret      = google_secret_manager_secret.certs_csr[0].id
  secret_data = var.enterprise_config.https_certs.cert
}

resource "google_secret_manager_secret_iam_member" "cert_csr_access" {
  count     = local.https_enabled ? 1 : 0
  secret_id = google_secret_manager_secret.certs_csr[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_secret_manager_secret" "certs_key" {
  count     = local.https_enabled ? 1 : 0
  secret_id = "${var.name}-certs-key"

  replication {
    user_managed {
      replicas {
        location = local.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "cert_key_value" {
  count       = local.https_enabled ? 1 : 0
  secret      = google_secret_manager_secret.certs_key[0].id
  secret_data = var.enterprise_config.https_certs.key
}

resource "google_secret_manager_secret_iam_member" "cert_key_access" {
  count     = local.https_enabled ? 1 : 0
  secret_id = google_secret_manager_secret.certs_key[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.controller_sa.email}"
}
