resource "azurerm_storage_account" "sa" {
  name                     = lower(replace(var.storage_account_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.account_replication_type
  min_tls_version          = var.min_tls_version

  tags = var.tags
}
