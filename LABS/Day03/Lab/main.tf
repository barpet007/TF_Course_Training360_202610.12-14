terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    lab       = "LAB03"
    managedBy = "terraform"
  }
}

resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(local.common_tags, {
    environment = var.environment
  })
}

module "storage" {
  source = "./modules/simple_storage"

  resource_group_name      = azurerm_resource_group.lab.name
  location                 = azurerm_resource_group.lab.location
  storage_account_name     = var.storage_account_name
  account_replication_type = var.storage_account_replication_type
  min_tls_version          = var.storage_account_min_tls_version
  tags                     = merge(local.common_tags, { environment = var.environment })
}
