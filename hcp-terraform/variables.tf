variable "organization" {
  description = "HCP Terraform organization name."
  type        = string
}

variable "vcs_repo_identifier" {
  description = "Git repository in ORG/REPO form."
  type        = string
}

variable "vcs_oauth_token_id" {
  description = "ID of the VCS OAuth connection / GitHub App installation in HCP Terraform."
  type        = string
}

variable "terraform_version" {
  description = "Terraform version pinned on every workspace."
  type        = string
  default     = "1.9.8"
}

variable "environments" {
  description = "Per-environment settings."
  type = map(object({
    project_id          = string
    run_service_account = string
    auto_apply          = bool
    branch              = string
  }))

  validation {
    condition     = alltrue([for k in keys(var.environments) : contains(["dev", "staging", "prod"], k)])
    error_message = "environments keys must be dev, staging or prod."
  }
}

variable "gcp_workload_provider_name" {
  description = "Full resource name of the Workload Identity provider trusted for HCP Terraform runs."
  type        = string
}

variable "vault_addr" {
  description = "Vault server URL."
  type        = string
}

variable "vault_run_role" {
  description = "Vault JWT auth role HCP Terraform runs authenticate as."
  type        = string
  default     = "tfc-gcp"
}
