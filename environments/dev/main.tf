module "platform" {
  source = "../../modules/platform"

  project_id            = var.project_id
  region                = var.region
  environment           = "dev"
  subnet_cidr           = var.subnet_cidr
  app_secret_id         = var.app_secret_id
  app_secret_project_id = var.app_secret_project_id
}
