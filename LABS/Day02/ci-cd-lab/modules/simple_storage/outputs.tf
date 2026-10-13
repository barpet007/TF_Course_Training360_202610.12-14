output "storage_account_id" {
  description = "The ID of the created Storage Account."
  value       = azurerm_storage_account.sa.id
}
