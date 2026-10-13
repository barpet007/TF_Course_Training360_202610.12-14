# Terraform CI/CD Pipeline with Checkov

## Cél

A lab célja, hogy egy egyszerű Azure infrastruktúrát egy újrafelhasználható Terraform modullal telepíts a rendszerbe Azure DevOps és egy védett CI/CD folyam segítségével. A gyakorlat a megfelelő sorrendet tanítja meg a biztonságos Azure remote backend, a Workload Identity Federation alapú Service Connection, az szándékosan hibás Checkov ellenőrzés, a javítás, a sikeres validáció, a Terraform plan, a kontrollált apply, az ellenőrzés és a tisztítás kapcsán.

## Lab folyamata

1. Előfeltételek
2. Azure Storage remote backend
3. Azure DevOps Service Connection
4. Szándékosan hibás Checkov ellenőrzés a Storage Account TLS szabályra
5. Hallgatói javítás a `TLS1_2` értékre
6. Sikeres Checkov ellenőrzés
7. Terraform plan
8. Ellenőrzött apply környezet-engedélyezés után
9. Ellenőrzés
10. Tisztítás

---

## 1. Előfeltételek

A lab kezdése előtt ellenőrizd a következőket:

- Azure CLI telepítve és bejelentkezve a célzott subscriptionre
- Azure DevOps szervezet és projekt létrehozva
- repository létrehozva az Azure DevOpsben
- hostolt agent vagy ehhez hasonló környezet elérhető
- Terraform feladatok elérhetők az Azure DevOpsben
- Azure DevOps environment neve `production`, engedélyezett jóváhagyási kapuval
- jogosultság Azure erőforráscsoportok és Storage Account létrehozására
- jogosultság Azure RBAC és Azure DevOps Service Connection konfigurálására

A lab nem hoz létre Azure-erőforrásokat Terraform apply vagy destroy parancsokból ebben a gyakorlatban. A beállító lépések először a szükséges közös backend erőforrásokat hozzák létre.

---

## 2. Közös backend és deployment resource groups

A pipeline lefutása előtt provisionáld a közös backend erőforrásokat és a deployment resource groupet.

Ezeket a neveket használd:

- Backend resource group: `tfstate-day2-rg`
- Deployment resource group: `tf-day2-lab-rg`

A backend erőforrások a labhoz közösek maradnak, és a szokásos hallgatói tisztítás során nem törölhetők addig, amíg a deployment erőforrásokat nem távolították el.

---

## 3. Terraform backend konfiguráció

A gyökér Terraform fájlnak a következő partial backendet kell tartalmaznia:

```hcl
terraform {
  backend "azurerm" {}
}
```

Ne a szokásos Terraform `-var` bemeneti argumentumokon keresztül add meg a backend értékeket. A backend értékeit a pipeline a `terraform init` futásakor adja meg az Azure DevOpsben.

A labban mindenhol ugyanaz a state keyet használjuk:

```text
day2-lab.terraform.tfstate
```

Ugyanazt az értéket használd a Terraform dokumentációban, a pipeline init feladatában, a beállítási leírásban és az előfeltétel dokumentációban.

---

## 4. Azure DevOps Service Connection

Az elsődleges, javasolt útvonal:

- Azure Resource Manager Service Connection
- Workload Identity Federation (WIF)
- nincs szükség hosszú életű client secretre

Hozd létre a Service Connectiont az Azure DevOps portálon, és ezt a nevet add neki:

```text
TF-SERVICE-CONNECTION
```

A Service Connectionnek a pipeline számára engedélyezettnek kell lennie, és a következő legkisebb jogosultságot kell kapnia:

- backend data-plane hozzáférés a `tfstate-day2-rg` csoportban lévő Storage Accounthez
- deployment jogosultság a `tf-day2-lab-rg` erőforráscsoporthoz

Ez a lab ajánlott útvonala.

### LEGACY ALTERNATIVE

A titkos alapú Azure service-principal flow csak akkor maradhat meg, ha egyértelműen megjelölt legacy alternativeként, régebbi környezetekhez. Ez nem a javasolt beállítás ebben a labban, és nem jelenhet meg az elsődleges útvonalként.

---

## 5. Változócsoport és pipeline értékek

Hozz létre egy `TF-SECRETS` nevű Azure DevOps változócsoportot, és add hozzá a következőket:

- `ARM_BACKEND_RG` = `tfstate-day2-rg`
- `ARM_BACKEND_SA` = a megosztott backend Storage Account neve
- `ARM_BACKEND_CONTAINER` = a backend container neve
- `ARM_BACKEND_KEY` = `day2-lab.terraform.tfstate`

`ARM_BACKEND_KEY` egy Terraform state kulcs, nem client secret. Nem helyettesíti az Azure hitelesítő adatokat.

---

## 6. Terraform modul szándékosan biztonsági hibával

A labnak szándékosan meg kell mutatnia egy olyan Storage Accountet, amely tudatosan nem felel meg a Checkov TLS szabályának.

A storage modulnak tartalmaznia kell egy egyértelmű oktatási megjegyzést:

```hcl
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
```

Ez a kötelező, szándékosan nem biztonságos oktatási konfiguráció. A hallgató javítása a következő:

```hcl
min_tls_version = "TLS1_2"
```

A Storage Accounthez tartozó helyes szabály ehhez a gyakorlathoz:

```text
CKV_AZURE_44
```

Ne használd a `CKV_AZURE_54` szabályt ehhez az oktatási feladathoz.

---

## 7. A pipeline első futása

Az első validációs lefutásnak szándékosan hibásnak kell lennie.

Példa parancs:

```bash
checkov --directory . --framework terraform --check CKV_AZURE_44
```

Várt eredmény:

- az első Checkov vizsgálat hibára fut a `CKV_AZURE_44` szabály miatt
- a pipeline megáll a plan szakasz előtt
- a hallgató kijavítja a TLS beállítást

---

## 8. Pipeline példa

Ez a várt pipeline modell:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: TF-SECRETS
  - name: location
    value: 'westeurope'
  - name: tfStateKey
    value: 'day2-lab.terraform.tfstate'

stages:
  - stage: CI_SCAN_PLAN
    displayName: 'Checkov Scan and Plan'
    jobs:
      - job: ScanAndPlan
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'

          - script: |
              python -m pip install --upgrade pip
              pip install checkov
            displayName: 'Install Checkov'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              backendType: 'azurerm'
              backendServiceArm: 'TF-SERVICE-CONNECTION'
              backendAzureRmResourceGroupName: $(ARM_BACKEND_RG)
              backendAzureRmStorageAccountName: $(ARM_BACKEND_SA)
              backendAzureRmContainerName: $(ARM_BACKEND_CONTAINER)
              backendAzureRmKey: 'day2-lab.terraform.tfstate'

          - script: |
              checkov --directory . --framework terraform --check CKV_AZURE_44
            displayName: 'Checkov Security Scan (expected to fail before remediation)'

          - task: TerraformTaskV4@4
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              environmentServiceNameAzureRM: 'TF-SERVICE-CONNECTION'
              commandOptions: '-out=tfplan -var="location=$(location)" -var="resource_group_name=tf-day2-lab-rg" -var="storage_account_name=tfday2labsa001"'

          - task: PublishPipelineArtifact@1
            displayName: 'Publish Terraform Plan'
            inputs:
              targetPath: '$(System.DefaultWorkingDirectory)/tfplan'
              artifact: 'terraform_plan'
              publishLocation: 'pipeline'

  - stage: CD_APPLY
    displayName: 'Deployment (Apply)'
    dependsOn: CI_SCAN_PLAN
    condition: succeeded('CI_SCAN_PLAN')
    jobs:
      - deployment: Apply
        displayName: 'Terraform Apply'
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self

                - task: DownloadPipelineArtifact@2
                  displayName: 'Download Terraform Plan'
                  inputs:
                    buildType: 'current'
                    artifactName: 'terraform_plan'
                    targetPath: '$(System.DefaultWorkingDirectory)'

                - task: TerraformInstaller@1
                  displayName: 'Install Terraform'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Init'
                  inputs:
                    provider: 'azurerm'
                    command: 'init'
                    backendType: 'azurerm'
                    backendServiceArm: 'TF-SERVICE-CONNECTION'
                    backendAzureRmResourceGroupName: $(ARM_BACKEND_RG)
                    backendAzureRmStorageAccountName: $(ARM_BACKEND_SA)
                    backendAzureRmContainerName: $(ARM_BACKEND_CONTAINER)
                    backendAzureRmKey: 'day2-lab.terraform.tfstate'

                - task: TerraformTaskV4@4
                  displayName: 'Terraform Apply'
                  inputs:
                    provider: 'azurerm'
                    command: 'apply'
                    environmentServiceNameAzureRM: 'TF-SERVICE-CONNECTION'
                    commandOptions: 'tfplan'
```

---

## 9. Tisztítás

A tisztításnak külön kell kezelnie a lab deployment erőforrásait és a megosztott backend erőforrásokat.

A. Lab deployment erőforrások
- távolítsd el a `tf-day2-lab-rg` erőforráscsoporton belüli erőforrásokat
- ha szükséges, távolítsd el a `tf-day2-lab-rg` erőforráscsoportot is

B. Megosztott backend erőforrások
- tartsd meg a közös backend Storage Accountet
- tartsd meg a backend containert
- ne töröld a state blobet addig, amíg a lab erőforrásai már nem lettek tisztítva

A sikeres apply után töröld a deployment erőforráscsoportban lévő erőforrásokat, majd ha szükséges, távolítsd el az erőforráscsoportot is.

A sikertelen pipeline után nézd át a hibás job logjait, javítsd a konfiguráció hibáját, majd csak a deployment erőforrásokat tisztítsd meg.

Ha a felhőben manuálisan törlés történik, ellenőrizd, hogy az állapot konzisztense maradjon, és a backend továbbra is megmaradjon, amíg a lab teljesen le nem lett takarítva.

Ha a deployment részben elkészült, távolítsd el a létrehozott erőforráscsoport tartalmát a state blob törlése előtt, és csak ezután tisztítsd meg a backend state tárolót, ha ezt szándékosan meg kell tenni.

Ne hozz létre alapértelmezetten védetlen destroy pipeline szakaszt. Ha a destroy szakasz dokumentálva van, az explicit, kézi jóváhagyással történő, és nyilvánvalóan elkülönített legyen a normál labfolyamottól.

---

## 10. Biztonsági emlékeztető

Soha ne commitolj valós hitelesítő adatokat, generált titkos kulcsokat vagy `prereqs_output.json` fájlt a source controlba.

Ha a mintafájlt meg kell tartani, akkor csak helyőrző értékeket tartalmazzon, és egyértelműen jelezze, hogy mintaadatokról van szó.

A jóváhagyásokat az Azure DevOps `production` environmentben konfigurálják, nem egy YAML kommentben. Az environment-ben megadott jóváhagyási kapu az, amely szabályozza az apply szakaszt.
