output "controller_id" {
  description = "The ID of the controller instance"
  value       = nebius_compute_v1_instance.controller.id
}

output "controller_name" {
  description = "The name of the controller instance"
  value       = nebius_compute_v1_instance.controller.name
}


output "service_account_id" {
  description = "The ID of the controller service account"
  value       = nebius_iam_v1_service_account.controller_sa.id
}
