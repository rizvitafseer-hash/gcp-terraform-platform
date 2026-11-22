resource "tfe_workspace" "env" {
  for_each = var.environments

  name              = "gcp-${each.key}"
  description       = "GCP ${each.key} environment"
  working_directory = "environments/${each.key}"
  terraform_version = var.terraform_version
  auto_apply        = each.value.auto_apply # only dev auto-applies
  tag_names         = ["gcp", each.key]

  # Scheduled drift / health checks.
  assessments_enabled = true

  # Re-run when the environment or any shared module changes.
  trigger_patterns = [
    "environments/${each.key}/**/*",
    "modules/**/*",
  ]

  vcs_repo {
    identifier     = var.vcs_repo_identifier
    branch         = each.value.branch
    oauth_token_id = var.vcs_oauth_token_id
  }
}

# --- Per-workspace values -------------------------------------------------
resource "tfe_variable" "project_id" {
  for_each = var.environments

  workspace_id = tfe_workspace.env[each.key].id
  category     = "terraform"
  key          = "project_id"
  value        = each.value.project_id
  description  = "GCP project for ${each.key}"
}

resource "tfe_variable" "run_service_account" {
  for_each = var.environments

  workspace_id = tfe_workspace.env[each.key].id
  category     = "env"
  key          = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value        = each.value.run_service_account
}

# --- Shared dynamic-credential settings (GCP WIF + Vault JWT) ---------------
resource "tfe_variable_set" "dynamic_credentials" {
  name        = "gcp-vault-dynamic-credentials"
  description = "Short-lived credentials for GCP and Vault. No static keys."
}

locals {
  dynamic_credential_vars = {
    TFC_GCP_PROVIDER_AUTH          = "true"
    TFC_GCP_WORKLOAD_PROVIDER_NAME = var.gcp_workload_provider_name
    TFC_VAULT_PROVIDER_AUTH        = "true"
    TFC_VAULT_ADDR                 = var.vault_addr
    TFC_VAULT_RUN_ROLE             = var.vault_run_role
  }
}

resource "tfe_variable" "dynamic_credentials" {
  for_each = local.dynamic_credential_vars

  variable_set_id = tfe_variable_set.dynamic_credentials.id
  category        = "env"
  key             = each.key
  value           = each.value
}

resource "tfe_workspace_variable_set" "dynamic_credentials" {
  for_each = tfe_workspace.env

  variable_set_id = tfe_variable_set.dynamic_credentials.id
  workspace_id    = each.value.id
}

# --- Policy as code (OPA) ---------------------------------------------------
resource "tfe_policy_set" "gcp_guardrails" {
  name         = "gcp-guardrails"
  description  = "OPA guardrails evaluated on every run"
  kind         = "opa"
  overridable  = false
  organization = var.organization

  policies_path = "policies/opa"

  vcs_repo {
    identifier     = var.vcs_repo_identifier
    branch         = "main"
    oauth_token_id = var.vcs_oauth_token_id
  }

  workspace_ids = [for ws in tfe_workspace.env : ws.id]
}
