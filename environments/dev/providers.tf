# GCP credentials come from HCP Terraform dynamic provider credentials
# (workload identity federation): no service-account keys anywhere.
provider "google" {
  project = var.project_id
  region  = var.region
}

# The Vault token is injected by HCP Terraform (TFC_VAULT_PROVIDER_AUTH), so
# the provider is configured with the address only.
provider "vault" {
  address          = var.vault_address
  skip_child_token = true
}
