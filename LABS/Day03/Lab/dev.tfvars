# TRAINING ONLY
# These values are intentionally non-compliant so students can observe
# the Checkov policy gate. Do not use these values in production.

environment                      = "dev"
location                         = "westeurope"
resource_group_name              = "RG-DEV-LAB03"
storage_account_name             = "stdevlab03replace"
storage_account_replication_type = "LRS"
storage_account_min_tls_version  = "TLS1_0"
