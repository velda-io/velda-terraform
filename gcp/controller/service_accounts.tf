data "google_service_account" "controller_sa" {
  project    = var.project
  account_id = "${var.name}-controller"
}

data "google_service_account" "agent_sa" {
  project    = var.project
  account_id = "${var.name}-agent"
}

resource "google_project_iam_member" "controller_k8s" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"

  member = "serviceAccount:${data.google_service_account.controller_sa.email}"
}
resource "google_project_iam_member" "controller_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"

  member = "serviceAccount:${data.google_service_account.controller_sa.email}"
}

resource "google_project_iam_member" "controller_monitoring_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"

  member = "serviceAccount:${data.google_service_account.controller_sa.email}"
}


resource "google_project_iam_member" "agent_monitoring_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"

  member = "serviceAccount:${data.google_service_account.agent_sa.email}"
}
resource "google_project_iam_member" "agent_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"

  member = "serviceAccount:${data.google_service_account.agent_sa.email}"
}
