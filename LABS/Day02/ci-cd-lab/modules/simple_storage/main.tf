resource "azurerm_storage_account" "sa" {
  name                     = lower(replace(var.storage_account_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # INTENTIONAL INSECURE CONFIGURATION FOR CHECKOV TRAINING
  # Students will remediate this to TLS1_2 during the lab.
  # This is not production guidance.
  min_tls_version = "TLS1_0"
}
