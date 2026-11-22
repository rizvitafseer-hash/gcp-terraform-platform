output "vpc_name" {
  description = "VPC name."
  value       = module.platform.vpc_name
}

output "subnet_name" {
  description = "Subnet name."
  value       = module.platform.subnet_name
}

output "storage_bucket" {
  description = "Data bucket name."
  value       = module.platform.storage_bucket
}

output "app_service_account_email" {
  description = "Application service account email."
  value       = module.platform.app_service_account_email
}
