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

variable "vault_kv_mount" {
  description = "Vault KV v2 mount that holds application secrets."
  type        = string
  default     = "secret"
}

variable "vault_secret_path" {
  description = "Path of the KV v2 secret to copy into GCP Secret Manager. Null disables the Vault integration."
  type        = string
  default     = null
}
