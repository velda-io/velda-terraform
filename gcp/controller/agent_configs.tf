resource "google_storage_bucket" "pool_configs" {
  project = var.project
  name     = "${var.project}-${var.name}-configs"
  location = local.region

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "controller_sa_reader" {
  bucket = google_storage_bucket.pool_configs.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_service_account.controller_sa.email}"
}