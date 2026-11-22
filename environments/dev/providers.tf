# Authentication uses Application Default Credentials:
#   local:  gcloud auth application-default login
#   CI:     workload identity federation / attached service account
# No service-account keys are stored in this repository.
provider "google" {
  project = var.project_id
  region  = var.region
}
