resource "google_storage_bucket" "data" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = "STANDARD"
  force_destroy = var.force_destroy
  labels        = var.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # Expire only *old versions*. (A plain age rule expires live objects too,
  # silently deleting current data.)
  lifecycle_rule {
    condition {
      age        = var.noncurrent_version_retention_days
      with_state = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }

  lifecycle {
    # Fail the plan, not the apply, if someone weakens the security baseline.
    precondition {
      condition     = !var.force_destroy || lookup(var.labels, "environment", "") != "prod"
      error_message = "force_destroy must not be enabled for prod buckets."
    }

    postcondition {
      condition     = self.public_access_prevention == "enforced"
      error_message = "Bucket must enforce public access prevention."
    }
  }
}
