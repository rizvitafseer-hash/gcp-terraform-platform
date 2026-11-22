terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  # HCP Terraform provides remote state, state locking, run history and policy
  # enforcement. The organisation comes from the TF_CLOUD_ORGANIZATION
  # environment variable so no org name is hard-coded in the repository.
  cloud {
    workspaces {
      name = "gcp-prod"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0, < 6.0"
    }
  }
}
