variable "project_id" {
  description = "GCP project ID for this environment."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "subnet_cidr" {
  description = "Subnet CIDR for this environment. Keep ranges non-overlapping across environments."
  type        = string
}

variable "labels" {
  description = "Extra labels merged over the mandatory ones."
  type        = map(string)
  default     = {}
}

variable "enabled_apis" {
  description = "Google APIs to enable before any resource is created."
  type        = set(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}

variable "app_secret_id" {
  description = "ID (short name) of an existing Secret Manager secret the app service account may read. Null disables it."
  type        = string
  default     = null
}

variable "app_secret_project_id" {
  description = "Project that holds the secret. Null means var.project_id."
  type        = string
  default     = null
}
