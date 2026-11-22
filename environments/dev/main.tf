module "platform" {
  source = "../../modules/platform"

  project_id        = var.project_id
  region            = var.region
  environment       = "dev"
  subnet_cidr       = var.subnet_cidr
  vault_secret_path = var.vault_secret_path
}
