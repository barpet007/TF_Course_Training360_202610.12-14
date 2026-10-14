variable "resource_group_name" {
  description = "Name of the resource group that hosts the storage account."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account to create."
  type        = string
}

variable "account_replication_type" {
  description = "Replication type for the storage account (LRS or GRS)."
  type        = string
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account."
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to the storage account."
  type        = map(string)
  default     = {}
}
