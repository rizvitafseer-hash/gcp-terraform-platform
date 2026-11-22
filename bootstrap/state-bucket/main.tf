# Creates the GCS bucket that stores Terraform state for all environments.
# Apply this ONCE first (local state), then run `terraform init` in each
# environment. The gcs backend locks state natively.
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "Project that will host the state bucket."
  type        = string
}

variable "region" {
  description = "Bucket location."
  type        = string
  default     = "asia-south1"
}

resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-terraform-state"
  project       = var.project_id
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 30
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "state_bucket" {
  description = "Use as `bucket` in each environment's gcs backend block."
  value       = google_storage_bucket.terraform_state.name
}
