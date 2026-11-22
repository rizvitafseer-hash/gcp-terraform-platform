output "project_number" {
  description = "Numeric project number."
  value       = data.google_project.this.number
}

output "vpc_name" {
  description = "VPC name."
  value       = module.network.network_name
}

output "subnet_name" {
  description = "Subnet name."
  value       = module.network.subnet_name
}

output "storage_bucket" {
  description = "Data bucket name."
  value       = module.storage.bucket_name
}

output "app_service_account_email" {
  description = "Application service account email."
  value       = google_service_account.app.email
}

output "app_secret_id" {
  description = "Secret Manager secret the app service account can read (null if disabled)."
  value       = one(data.google_secret_manager_secret.app[*].secret_id)
}
