provider "azurerm" {
  features {}
}

variable "storage_name" {
  description = "Globally unique name for the storage account."
  type        = string
}

resource "azurerm_resource_group" "example" {
  name     = "module-demo-rg"
  location = "West Europe"
}

module "website_storage" {
  source = "./modules/my-storage"

  storage_name = var.storage_name
  rg_name      = azurerm_resource_group.example.name
  location     = azurerm_resource_group.example.location
}

output "final_storage_id" {
  value = module.website_storage.storage_id
}