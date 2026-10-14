output "resource_group_name" {
  description = "Name of the environment resource group."
  value       = azurerm_resource_group.lab.name
}

output "storage_account_name" {
  description = "Name of the storage account provisioned by the lab."
  value       = module.storage.storage_account_name
}

output "storage_account_id" {
  description = "Resource ID of the storage account provisioned by the lab."
  value       = module.storage.storage_account_id
}
