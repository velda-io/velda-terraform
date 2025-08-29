resource "google_service_account" "controller_sa" {
  project    = var.project
  account_id = "${var.name}-controller"
}

resource "google_service_account" "agent_sa" {
  project    = var.project
  account_id = "${var.name}-agent"
}

resource "google_project_iam_member" "controller_instance_manage" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"

  member = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_project_iam_member" "controller_log_writer" {
  count   = var.enable_monitoring ? 1 : 0
  project = var.project
  role    = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_project_iam_member" "controller_monitoring_metric_writer" {
  count   = var.enable_monitoring ? 1 : 0
  project = var.project
  role    = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.controller_sa.email}"
}

resource "google_project_iam_member" "agent_monitoring_metric_writer" {
  count   = var.enable_monitoring ? 1 : 0
  project = var.project
  role    = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.agent_sa.email}"
}

resource "google_project_iam_member" "agent_log_writer" {
  count   = var.enable_monitoring ? 1 : 0
  project = var.project
  role    = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.agent_sa.email}"
}
