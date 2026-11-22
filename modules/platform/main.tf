data "google_project" "this" {
  project_id = var.project_id
}

locals {
  prefix = "ent-${var.environment}"

  # Mandatory labels win over caller-supplied ones.
  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    owner       = "platform-team"
  })

  is_prod = var.environment == "prod"
}

# ---------------------------------------------------------------------------
# APIs must exist before anything that uses them (explicit dependency).
# ---------------------------------------------------------------------------
resource "google_project_service" "apis" {
  for_each = var.enabled_apis

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Network + storage (reusable child modules)
# ---------------------------------------------------------------------------
module "network" {
  source = "../network"

  project_id   = var.project_id
  region       = var.region
  network_name = "${local.prefix}-vpc"
  subnet_cidr  = var.subnet_cidr

  # Cut flow-log cost outside prod.
  flow_log_sampling = local.is_prod ? 0.5 : 0.1

  depends_on = [google_project_service.apis]
}

module "storage" {
  source = "../storage"

  project_id  = var.project_id
  location    = var.region
  bucket_name = "${var.project_id}-${var.environment}-data"
  labels      = local.labels

  # Longer version history where recovery matters most.
  noncurrent_version_retention_days = local.is_prod ? 365 : 30

  depends_on = [google_project_service.apis]
}

# ---------------------------------------------------------------------------
# Workload identity + least-privilege access to the bucket
# ---------------------------------------------------------------------------
resource "google_service_account" "app" {
  project      = var.project_id
  account_id   = "${local.prefix}-app"
  display_name = "${var.environment} application service account"

  depends_on = [google_project_service.apis]
}

resource "google_storage_bucket_iam_member" "app_object_user" {
  bucket = module.storage.bucket_name
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${google_service_account.app.email}"
}

# ---------------------------------------------------------------------------
# Existing GCP Secret Manager secret (created and populated outside Terraform,
# so the secret value never enters code, tfvars or Terraform state). The app
# service account is granted read access; the app fetches the value at runtime.
# ---------------------------------------------------------------------------
data "google_secret_manager_secret" "app" {
  count = var.app_secret_id == null ? 0 : 1

  project   = coalesce(var.app_secret_project_id, var.project_id)
  secret_id = var.app_secret_id

  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_iam_member" "app_accessor" {
  count = var.app_secret_id == null ? 0 : 1

  project   = data.google_secret_manager_secret.app[0].project
  secret_id = data.google_secret_manager_secret.app[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app.email}"
}
