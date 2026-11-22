variable "project_id" {
  description = "GCP project that owns the bucket."
  type        = string
}

variable "location" {
  description = "Bucket location (region or multi-region), e.g. asia-south1."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 chars of lowercase letters, digits, '.', '_' or '-', starting and ending alphanumeric."
  }
}

variable "labels" {
  description = "Labels applied to the bucket."
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow deletion of a non-empty bucket. Keep false everywhere except throw-away sandboxes."
  type        = bool
  default     = false
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep noncurrent (overwritten/deleted) object versions before removal. Live objects are never expired by this module."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days >= 1
    error_message = "noncurrent_version_retention_days must be >= 1."
  }
}

variable "kms_key_name" {
  description = "Optional Cloud KMS key (full resource name) for CMEK. Null uses Google-managed encryption."
  type        = string
  default     = null
}
