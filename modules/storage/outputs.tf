output "bucket_name" {
  description = "Bucket name."
  value       = google_storage_bucket.data.name
}

output "bucket_url" {
  description = "gs:// URL of the bucket."
  value       = google_storage_bucket.data.url
}

output "bucket_self_link" {
  description = "Bucket self link."
  value       = google_storage_bucket.data.self_link
}
