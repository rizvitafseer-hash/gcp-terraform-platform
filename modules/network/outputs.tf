output "network_name" {
  description = "VPC name."
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "VPC resource ID."
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "VPC self link."
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Subnet name."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_id" {
  description = "Subnet resource ID."
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_cidr" {
  description = "Subnet primary CIDR range."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}
