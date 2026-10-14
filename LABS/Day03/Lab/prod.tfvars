# Secure baseline for the PRD branch.

environment                      = "prod"
location                         = "westeurope"
resource_group_name              = "rg-PRD-LAB03"
storage_account_name             = "stprdlab03replace"
storage_account_replication_type = "GRS"
storage_account_min_tls_version  = "TLS1_2"
