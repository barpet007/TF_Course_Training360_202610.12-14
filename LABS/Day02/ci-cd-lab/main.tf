terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

module "storage_deploy" {
  source = "./modules/simple_storage"

  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
  location             = var.location
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  description = "Existing deployment resource group managed by the lab."
  type        = string
  default     = "tf-day2-lab-rg"
}

variable "storage_account_name" {
  description = "Name of the storage account to deploy into the existing lab resource group."
  type        = string
  default     = "tfday2labsa001"
}
