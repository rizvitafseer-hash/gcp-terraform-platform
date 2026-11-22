variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR for this environment."
  type        = string
}

variable "app_secret_id" {
  description = "ID of an existing Secret Manager secret the app service account may read. Null disables it."
  type        = string
  default     = null
}

variable "app_secret_project_id" {
  description = "Project that holds the secret. Null means var.project_id."
  type        = string
  default     = null
}
