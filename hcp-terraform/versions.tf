# Manages HCP Terraform itself (workspaces, variables, policy sets) as code.
# Run once by a platform admin; its own state lives in a dedicated workspace
# or locally. Authenticate with TFE_TOKEN (a team/org token).
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.58"
    }
  }
}

provider "tfe" {
  organization = var.organization
}
