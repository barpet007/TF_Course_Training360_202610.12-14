variable "environment" {
  description = "Deployment environment name (dev or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], lower(var.environment))
    error_message = "environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region for the lab resources."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the target resource group."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account to deploy. Replace the placeholder with a globally unique lowercase alphanumeric value before deployment."
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "storage_account_name must be between 3 and 24 characters."
  }
}

variable "storage_account_replication_type" {
  description = "Storage replication type. The training lab intentionally starts with LRS so students can observe the Checkov failure before remediation."
  type        = string

  validation {
    condition     = contains(["LRS", "GRS"], upper(var.storage_account_replication_type))
    error_message = "storage_account_replication_type must be LRS or GRS."
  }
}

variable "storage_account_min_tls_version" {
  description = "Minimum TLS version for the storage account. The training lab intentionally starts with TLS1_0 so students can observe the Checkov failure before remediation."
  type        = string

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], upper(var.storage_account_min_tls_version))
    error_message = "storage_account_min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "common_tags" {
  description = "Optional extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
