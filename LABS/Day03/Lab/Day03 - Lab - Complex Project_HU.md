# Day 03 labor - branch-alapú DEV / PRD Terraform deployment

## Cél

Készíts egy Terraform + Azure DevOps laboratóriumi feladatot, amely két ágat és két telepítési célpontot használ:

- a `develop` branch automatikusan telepít a DEV környezetbe a `RG-DEV-LAB03` erőforráscsoportban
- a `main` branch a PRD környezetbe telepít a `rg-PRD-LAB03` erőforráscsoportban
- a DEV környezet automatikusan települ a push után
- a PRD környezet előzetes jóváhagyást igényel mind a CI, mind a CD folyamatban az Azure DevOpsben
- a Checkov blokkolja a nem biztonságos tárolási beállításokat, amíg a kód nem kerül javításra

Ez a változat a Day 03 alá készült, és lecseréli a régebbi, egy környezetre épülő laborfolyamot.

## Mire van már kész a projekt

A korábbi labor már tartalmazza ezeket az Azure DevOps elemeket, ezért ne hozd őket létre újra:

- Service Connection
- `TF-SECRETS` változócsoport

## Azure DevOps repo beállítása

Az Azure DevOpsben hozz létre egy új Git repositoryt `TFCourseDAY03LAB` néven.

Hozd létre a branch-struktúrát így:

- a `main` a base branch
- a `develop` a `main` alapján jön létre

## Mi történik az egyes brancheken

- `develop` branch:
  - DEV-specifikus Terraform kód
  - `dev.tfvars`
  - beállítások, amelyek a `RG-DEV-LAB03` környezetbe telepítenek
  - ide történő push esetén a DEV telepítés automatikusan elindul

- `main` branch:
  - PRD-specifikus Terraform kód
  - `prod.tfvars`
  - beállítások, amelyek a `rg-PRD-LAB03` környezetbe telepítenek
  - a PRD a CD folyamata előtt jóváhagyásra vár

Ha ellenőrizni szeretnéd, hogy mi már létezik, nézd meg az előző labor jegyzeteit vagy az Azure DevOps projekt beállításait.

## Branch modell

- `develop` -> DEV deployment
- `main` -> PRD deployment
- Opcionális kézi felülírás a pipeline paraméterein keresztül:
  - `auto`
  - `dev`
  - `prod`
  - `plan`
  - `apply`
  - `destroy`

## Várt környezetek

- A DEV erőforrások a `RG-DEV-LAB03` erőforráscsoportba mennek
- A PRD erőforrások a `rg-PRD-LAB03` erőforráscsoportba mennek

## Szándékosan hibás Checkov eredmények

A kezdeti DEV konfigurációban szándékosan hibásnak kell lennie a Checkovnak két vezérlőn:

- a Storage Account TLS verziója túl gyenge: `TLS1_0`
- a Storage Account replikációja `LRS`, nem pedig `GRS`

A beállítások javítása után a CI-nek sikeresnek kell lennie, és a CD folyamata tovább tud lépni.

> **Fontos**
>
> A DEV konfigurációban szereplő `TLS1_0` és `LRS` értékek szándékosan nem felelnek meg a labor biztonsági szabályainak. Ezek kizárólag oktatási célból szerepelnek a kiindulási konfigurációban.
>
> Ez a konfiguráció nem production ajánlás; ez a labor célzott, tanulási szándékú kezdőállapota.

## Javasolt projektstruktúra

```text
/
├── modules/
│   └── simple_storage/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── dev.tfvars
├── prod.tfvars
├── azure-pipelines.yml
├── checkov/
│   └── custom_policies/
└── scripts/
    └── bootstrap_prereqs.ps1
```

## Terraform root module

`main.tf`

```terraform
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

output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}
```

`versions.tf`

```terraform
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

`variables.tf`

```terraform
variable "environment" {
  description = "Deployment environment name (dev or prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], lower(var.environment))
    error_message = "environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region for the lab resources."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the target resource group."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account to deploy."
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "storage_account_name must be between 3 and 24 characters."
  }
}

variable "storage_account_replication_type" {
  description = "Storage replication type (LRS for dev lab failure, GRS for production)."
  type        = string

  validation {
    condition     = contains(["LRS", "GRS"], upper(var.storage_account_replication_type))
    error_message = "storage_account_replication_type must be LRS or GRS."
  }
}

variable "storage_account_min_tls_version" {
  description = "Minimum TLS version for the storage account."
  type        = string

  validation {
    condition     = contains(["TLS1_0", "TLS1_1", "TLS1_2"], upper(var.storage_account_min_tls_version))
    error_message = "storage_account_min_tls_version must be TLS1_0, TLS1_1, or TLS1_2."
  }
}

variable "common_tags" {
  description = "Optional extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
```

## Storage module

`modules/simple_storage/main.tf`

```terraform
resource "azurerm_storage_account" "sa" {
  name                     = lower(replace(var.storage_account_name, "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.account_replication_type
  min_tls_version          = var.min_tls_version

  tags = var.tags
}
```

`modules/simple_storage/variables.tf`

```terraform
variable "resource_group_name" {
  description = "Name of the resource group that hosts the storage account."
  type        = string
}

variable "location" {
  description = "Azure region for the storage account."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account to create."
  type        = string
}

variable "account_replication_type" {
  description = "Replication type for the storage account (LRS or GRS)."
  type        = string
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account."
  type        = string
}

variable "tags" {
  description = "Optional tags to apply to the storage account."
  type        = map(string)
  default     = {}
}
```

`modules/simple_storage/outputs.tf`

```terraform
output "storage_account_id" {
  description = "ID of the created storage account."
  value       = azurerm_storage_account.sa.id
}

output "storage_account_name" {
  description = "Name of the created storage account."
  value       = azurerm_storage_account.sa.name
}
```

## Környezeti tfvars fájlok

`dev.tfvars`

```hcl
environment                      = "dev"
location                         = "westeurope"
resource_group_name              = "RG-DEV-LAB03"
storage_account_name             = "stdevlab03"
storage_account_replication_type = "LRS"
storage_account_min_tls_version  = "TLS1_0"
```

`prod.tfvars`

```hcl
environment                      = "prod"
location                         = "westeurope"
resource_group_name              = "rg-PRD-LAB03"
storage_account_name             = "stprdlab03"
storage_account_replication_type = "GRS"
storage_account_min_tls_version  = "TLS1_2"
```

## Azure DevOps pipeline

A pipeline-nek a következőket kell tudnia:

- triggereljen a `develop` és a `main` branchekre
- a branch alapján automatikusan határozza meg a környezetet, vagy a felhasználó paraméterrel felülírhatja azt
- a CI és a CD során is futtassa a Terraform initet
- a plan előtt fusson le a Checkov
- a planet a pipeline artifactként publikálja a CI-ben
- a CD-ben letöltse az artifactet
- támogassa a `plan`, `apply` és `destroy` műveleteket

### Pipeline vázlat

```yaml
trigger:
  branches:
    include:
      - develop
      - main

parameters:
  - name: environmentMode
    type: string
    default: auto
    values:
      - auto
      - dev
      - prod

  - name: terraformAction
    type: string
    default: apply
    values:
      - plan
      - apply
      - destroy

stages:
  - stage: CI
    displayName: CI - Validate, Scan, Plan
    jobs:
      - job: Plan
        steps:
          - checkout: self
          - task: TerraformInstaller@1
          - script: pip install checkov
          - task: TerraformTaskV4@4
            displayName: Terraform Init
          - script: checkov --directory . --framework terraform --external-checks-dir ./checkov/custom_policies
          - task: TerraformTaskV4@4
            displayName: Terraform Plan
          - task: PublishPipelineArtifact@1
            displayName: Publish Terraform Plan

  - stage: CD
    displayName: CD - Apply or Destroy
    dependsOn: CI
    jobs:
      - deployment: DeployDev
        displayName: DEV deployment
        condition: or(eq('${{ parameters.environmentMode }}', 'dev'), and(eq('${{ parameters.environmentMode }}', 'auto'), ne(variables['Build.SourceBranchName'], 'main')))
        environment: 'DEV-LAB03'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - task: DownloadPipelineArtifact@2
                - task: TerraformInstaller@1
                - task: TerraformTaskV4@4
                  displayName: Terraform Init
                - task: TerraformTaskV4@4
                  displayName: Terraform Apply
                - task: TerraformTaskV4@4
                  displayName: Terraform Destroy

      - deployment: DeployProd
        displayName: PRD deployment
        condition: or(eq('${{ parameters.environmentMode }}', 'prod'), and(eq('${{ parameters.environmentMode }}', 'auto'), eq(variables['Build.SourceBranchName'], 'main')))
        environment: 'PRD-LAB03'
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: self
                - task: DownloadPipelineArtifact@2
                - task: TerraformInstaller@1
                - task: TerraformTaskV4@4
                  displayName: Terraform Init
                - task: TerraformTaskV4@4
                  displayName: Terraform Apply
                - task: TerraformTaskV4@4
                  displayName: Terraform Destroy
```

## Checkov policy-k

Bővítsd a projektet saját policy-kel, hogy a labor szándékosan hibára fusson, amíg a kód nem kerül javításra:

- a TLS-nek `TLS1_2`-nek kell lennie
- a replikációnak `GRS`-nek kell lennie

Példa fájlok:

`checkov/custom_policies/storage_tls.yaml`

```yaml
metadata:
  name: Azure Storage accounts must use TLS 1.2
  id: CKV_CUSTOM_STORAGE_TLS_1
  category: ENCRYPTION
definition:
  cond_type: attribute
  resource_types:
    - azurerm_storage_account
  attribute: min_tls_version
  operator: equals
  value: TLS1_2
```

`checkov/custom_policies/storage_replication.yaml`

```yaml
metadata:
  name: Azure Storage accounts must use GRS replication
  id: CKV_CUSTOM_STORAGE_REPL_1
  category: BACKUP AND RECOVERY
definition:
  cond_type: attribute
  resource_types:
    - azurerm_storage_account
  attribute: account_replication_type
  operator: equals
  value: GRS
```

## Előkészítő script

A script csak a backend tároló erőforrásait hozza létre. A Service Connection és az `TF-SECRETS` változócsoport már a korábbi laborból rendelkezésre áll.

`scripts/bootstrap_prereqs.ps1`

```powershell
param(
  [string]$Location = "westeurope",
  [string]$BackendResourceGroupName = "rg-lab03-backend",
  [string]$BackendStorageAccountName = "",
  [string]$BackendContainerName = "tfstate"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is not installed. Install az before running this script."
}

$azLogin = az account show --query id -o tsv 2>$null
if (-not $azLogin) {
  Write-Host "You are not signed in to Azure CLI. Run 'az login' first."
  exit 1
}

if ([string]::IsNullOrWhiteSpace($BackendStorageAccountName)) {
  $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
  $BackendStorageAccountName = "stlab03$randomSuffix"
}

az group create --name $BackendResourceGroupName --location $Location | Out-Null
az storage account create --name $BackendStorageAccountName --resource-group $BackendResourceGroupName --location $Location --sku Standard_LRS --kind StorageV2 | Out-Null
az storage container create --name $BackendContainerName --account-name $BackendStorageAccountName | Out-Null

$storageKey = az storage account keys list --resource-group $BackendResourceGroupName --account-name $BackendStorageAccountName --query "[0].value" -o tsv

$summary = [ordered]@{
  backendResourceGroup = $BackendResourceGroupName
  backendStorageAccount = $BackendStorageAccountName
  backendContainer      = $BackendContainerName
  backendKey            = $storageKey
  serviceConnection     = "Already prepared from the previous lab"
  variableGroup         = "Already prepared from the previous lab"
}

$summary | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $PSScriptRoot 'prereqs_output.json') -Encoding utf8
```

## Laborfolyam

1. Nyisd meg, vagy váltás a `develop` branchre.
2. Pushold a kód első változatát.
3. Figyeld meg, hogy a CI a Checkov miatt hibára fut, mert a `TLS1_0` és a `LRS` miatt nem felel meg a szabályoknak.
4. Javítsd a tárolási beállításokat a `dev.tfvars` fájlban vagy a root/module inputokban.
5. Pushold újra, és ellenőrizd, hogy a DEV automatikusan települ.
6. Merge-eld, vagy pushold a `main` branchre, és ellenőrizd, hogy a PRD előtt jóváhagyásra vár.
7. A pipeline paraméterei segítségével a `plan`, `apply` vagy `destroy` parancsokat használhatod szükség szerint.

## Megjegyzések

- A DEV és a PRD külön erőforráscsoportneveket használ.
- A CI-nek publikálnia kell a Terraform plan artifactet.
- A CD-nek a `apply` vagy `destroy` előtt ismét lefuttatnia kell a `terraform init` parancsot.
- A PRD környezetet Azure DevOps jóváhagyásokkal kell védeni.

## Mit tarts meg az előző laborból

Ezeket változatlanul meg kell tartani:

- Azure DevOps Service Connection
- `TF-SECRETS` változócsoport

Ezeket nem kell újra létrehozni.

## A DEV és PRD környezet különválasztása

A cél az, hogy a párhuzamos fejlesztés és a környezeti elkülönítés érthetően látszódjon:

- `develop` branch -> DEV környezet
- `main` branch -> PRD környezet

A `develop` branchen a konfiguráció célzottan a DEV környezetben való működésre készült, a `dev.tfvars` használatával. A `main` branchen a PRD konfiguráció közvetlenül a `prod.tfvars` értékeit használja, és a CD folyamat jóváhagyás előtt tovább nem lép.

Ez különösen fontos a Terraform state szempontjából is. A DEV és PRD nem osztozhat ugyanazon `terraform.tfstate` állományon, ezért külön state fájlt kell használni:

- DEV: `lab03/dev.terraform.tfstate`
- PRD: `lab03/prod.terraform.tfstate`

A különálló state fájlok biztosítják, hogy a DEV és a PRD környezet ne „kezelje” ugyanazt az infrastruktúrát véletlenül. A `backend "azurerm" {}` konfigurációhoz külön állománynév szükséges a két környezet között, és ezt a pipeline a branch alapján külön választja el.

## A Checkov custom policy-k célja

A klónozott, oktatási célú konfigurációban a következő kényszerek érvényesek:

- `CKV_CUSTOM_STORAGE_TLS_1` -> megköveteli, hogy a `min_tls_version` értéke `TLS1_2` legyen
- `CKV_CUSTOM_STORAGE_REPL_1` -> megköveteli, hogy az `account_replication_type` értéke `GRS` legyen

Ez a tanulási kör a következő:

```text
DEV konfiguráció
       |
       v
Checkov
       |
       v
FAIL
       |
       v
a policy findingek elemzése
       |
       v
diák javítása
       |
       v
Checkov
       |
       v
PASS
```

A `dev.tfvars` fájlban a diák a következő értékeket módosítja:

- `storage_account_min_tls_version = "TLS1_0"` -> `storage_account_min_tls_version = "TLS1_2"`
- `storage_account_replication_type = "LRS"` -> `storage_account_replication_type = "GRS"`

Ez a javítás a labor tanulási célját szolgálja: a DEV konfiguráció kezdetben nem biztonságos, majd a diák a lesson során a kényszerítő szabályoknak megfelelően rendbe teszi.

## Érdemleges megfigyelések és tanulságok

- A `develop` branch célja a gyors, automatikus DEV ciklus bemutatása.
- A `main` branch célja a PRD környezet védett, jóváhagyásra váró cselekvéseinek bemutatása.
- A Checkov célja, hogy a konzisztencia és a biztonság szempontjából fontos paramétereket ellenőrizze a kód módosítása előtt.
- A `storage_account_name` és az erőforráscsoportnevek célzottan jól látható helyőrzők; a tényleges környezetben ezeket egyedi, Azure-szabályoknak megfelelő értékekre kell cserélni.
- A pipeline feladata az, hogy a CI egy planet készítsen, a CD pedig külön környezetben ezt a planet felhasználva hajtsa végre a telepítést.

## Kérdés: mi történik itt?

- A labor arra tanít, hogy a DEV környezetben a konfiguráció kezdőállapotban szándékosan nem biztonságos.
- A Checkov a megadott, oktatási célú custom policy-k alapján blokkolja ezt a konfigurációt.
- A diák feladata az, hogy az értékeket a megfelelő, biztonságos állapotba állítsa.
- Ezzel a lab megmutatja a CI/CD és a Policy as Code megközelítés közötti kapcsolatot: a kód ne csak „működjön”, hanem a vállalati előírásoknak is megfeleljen.

## Fontos tudnivalók

- A `remote backend (távoli Terraform state-tárolás)` a labban a korábbi előkészületekhez kötődik, és a state fájlok külön környezetekben történő elkülönítését szolgálja.
- A pipelineben az `environment: production` az Azure DevOps környezetre utal, nem magára a Terraform konfigurációra.
- A jóváhagyás nem a YAML-ből jön létre; az Azure DevOps környezethez beállított engedélyezési és jóváhagyási szabályok határozzák meg.
- A `TF-SERVICE-CONNECTION` és a `TF-SECRETS` már a korábbi laborban elkészített, meglevő elemek, ezért őket itt nem kell újra létrehozni.

## Összefoglalás

Ez a Day 03 lab célja, hogy egy egyszerű, mégis valós tanulási környezetet mutasson be: a diák a `develop` branchen kezdi, látja a szándékosan rossz DEV konfigurációt, futtatja a Checkov ellenőrzést, megtalálja a hibákat, javítja a `dev.tfvars` értékeit, majd a PRD környezetre való előléptetés során a `main` branch és a jóváhagyási folyamat révén összefűzi a Terraform + Azure DevOps + Policy as Code alapelveket.

A labor nem az infrastruktúra létrehozását vagy az Azure felhatalmazások konfigurálását tartja a fő célpontnak, hanem a Terraform és a CI/CD folyamatok helyes használatának és a biztonsági szabályoknak a tanulását.
