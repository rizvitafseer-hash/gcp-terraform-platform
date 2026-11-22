terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  # Remote state in GCS (native locking). Create the bucket once with
  # bootstrap/state-bucket. Backend blocks cannot use variables, so the bucket
  # name is literal. Each environment has its own prefix.
  backend "gcs" {
    bucket = "project-3d116623-b2e3-4d71-83e-terraform-state"
    prefix = "env/prod"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
