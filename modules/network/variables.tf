variable "project_id" {
  description = "GCP project that owns the network."
  type        = string
}

variable "region" {
  description = "Region for the subnet."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC. The subnet and firewall rules derive their names from it."
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,53}[a-z0-9])?$", var.network_name))
    error_message = "network_name must be 1-55 chars, lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "subnet_cidr" {
  description = "Primary CIDR range of the subnet (RFC1918)."
  type        = string

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block, e.g. 10.10.0.0/24."
  }
}

variable "flow_log_sampling" {
  description = "VPC flow log sampling rate (0.0 - 1.0). Lower it in busy environments to control cost."
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_log_sampling >= 0 && var.flow_log_sampling <= 1
    error_message = "flow_log_sampling must be between 0 and 1."
  }
}

variable "enable_iap_ssh" {
  description = "Allow SSH from Google Identity-Aware Proxy to instances tagged 'allow-iap-ssh'."
  type        = bool
  default     = true
}
