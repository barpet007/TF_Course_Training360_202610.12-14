# Day 03 - Laboratórium

Ez a projekt a Day 03 Terraform + Azure DevOps lab kezdőállapotát tartalmazza.

## Cél

- `develop` ágon a DEV környezet automatikusan települ.
- `main` ágon a PRD környezet csak jóváhagyás után települ.
- A lab szándékosan kezdetben nem megfelelő konfigurációval indul, hogy a Checkov szabályok kivédjék a hibákat.

## Szándékosan hibás értékek

A `dev.tfvars` fájlban a következő értékek szándékosan nem megfelelők:

- `storage_account_replication_type = "LRS"`
- `storage_account_min_tls_version = "TLS1_0"`

A hallgató feladata ezek javítása:

- `LRS` -> `GRS`
- `TLS1_0` -> `TLS1_2`

## Elvárt Checkov szabályok

- `CKV_CUSTOM_STORAGE_TLS_1` legyen PASS
- `CKV_CUSTOM_STORAGE_REPL_1` legyen PASS

## Telepítés előtti teendők

- Ellenőrizze, hogy a korábbi labból már létezik a Service Connection és a `TF-SECRETS` változócsomag.
- Cserélje le a helyőrző storage account neveket egy egyedi, kisbetűs, alfanumerikus értékre.
- A backendet a bootstrap script hozza létre; a Terraform projekt nem tartalmaz hatékony titkos adatokat.

## Fájlok

- `main.tf` – gyökér Terraform konfiguráció
- `variables.tf` – bemeneti változók és validálás
- `dev.tfvars` / `prod.tfvars` – környezetspecifikus értékek
- `modules/simple_storage` – minimális tároló modul
- `checkov/custom_policies` – szándékosan hibás és megoldandó Checkov szabályok
- `scripts/bootstrap_prereqs.ps1` – backend előkészítő script

## Megjegyzés

Ez egy oktatási starter projekt; nem tartalmaz ideiglenes vagy valós titkot, és a lab célja a konfigurációkorlátozások megértése és javítása.
