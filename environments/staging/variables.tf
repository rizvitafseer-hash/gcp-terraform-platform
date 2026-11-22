variable "project_id" {
  description = "GCP project ID. Set as a Terraform variable on the HCP workspace."
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

variable "vault_address" {
  description = "Vault server URL (not a secret)."
  type        = string
}

variable "vault_secret_path" {
  description = "KV v2 path to sync into Secret Manager. Null disables it."
  type        = string
  default     = null
}
