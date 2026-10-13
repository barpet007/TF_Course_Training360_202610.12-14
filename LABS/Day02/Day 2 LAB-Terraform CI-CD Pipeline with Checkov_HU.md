# Advanced Modular Terraform Lab

## Cél

Telepíts egy egyszerű Azure-infrastruktúrát helyben Terraformrel. Ez a lab bemutatja:

- input validation
- `for_each`
- `depends_on`
- újrafelhasználható modulok

## Előfeltételek

Mielőtt hozzákezdenél, győződj meg róla, hogy:

- telepítve van a Terraform
- telepítve van az Azure CLI
- van olyan Azure-előfizetés, amelyhez hozzáférsz
- be vagy jelentkezve az Azure-be az `az login` parancs használatával

## Fájlstruktúra

```text
.
├── modules/
│   └── storage/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

## 1. Gyermekmodul

### `modules/storage/main.tf`

```terraform
resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type

  tags = {
    source = "terraform-module"
  }
}
```

### `modules/storage/variables.tf`

```terraform
variable "storage_account_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "replication_type" {
  type    = string
  default = "LRS"
}
```

### `modules/storage/outputs.tf`

```terraform
output "storage_account_id" {
  value = azurerm_storage_account.this.id
}
```

## 2. Gyökérkonfiguráció

### `variables.tf`

```terraform
variable "location" {
  type    = string
  default = "West Europe"
}

variable "prefix" {
  type    = string
  default = "lab-mod"
}

variable "environment" {
  description = "The target environment (dev or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment variable must be either 'dev' or 'prod'."
  }
}

variable "vnets" {
  description = "Map of VNets to create"
  type        = map(string)
  default = {
    frontend = "10.0.1.0/24"
    backend  = "10.0.2.0/24"
  }
}
```

### `main.tf`

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  for_each            = var.vnets
  name                = "${var.prefix}-${each.key}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  for_each             = var.vnets
  name                 = "default"
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_name  = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [each.value]
}

module "my_storage" {
  source = "./modules/storage"

  storage_account_name = "st${replace(var.prefix, "-", "")}${var.environment}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  replication_type     = "LRS"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet["frontend"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = fileexists("~/.ssh/id_rsa.pub") ? file("~/.ssh/id_rsa.pub") : "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [module.my_storage]
}
```

### `outputs.tf`

```terraform
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_id" {
  value = module.my_storage.storage_account_id
}
```

## 3. Helyi futtatás

Futtasd a Terraformet a repository gyökeréből:

```powershell
terraform init
terraform validate
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"
```

Ha ugyanazt a labot production beállításokkal akarod lefuttatni, használd a következőket:

```powershell
terraform plan -var="environment=prod"
terraform apply -var="environment=prod"
```

Használd a `prod` értéket arra, hogy ugyanazt a Terraform-folyamatot produkciós címkével mutasd be, így meg tudod mutatni, hogyan marad érvényes a validáció, hogyan változnak a nevek a kiválasztott környezettel, és miért fontos a production futások alapos átnézése az alkalmazás előtt.

## 4. Mit mutassunk be

Ez a lab bemutatja:

1. `input validation` — az `environment` csak `dev` vagy `prod` lehet
2. `for_each` — két VNet jön létre a `vnets` map alapján
3. `depends_on` — a VM vár a storage modulra
4. `reusable modules` — a storage account a `modules/storage` mappában van definiálva

## 5. Ellenőrzés

Ellenőrizd a plan kimenetét a következő erőforrásoknál:

- `azurerm_resource_group.rg`
- `azurerm_virtual_network.vnet["frontend"]`
- `azurerm_virtual_network.vnet["backend"]`
- `module.my_storage.azurerm_storage_account.this`
- `azurerm_linux_virtual_machine.vm`

## 6. Opcionális tisztítás

Ha elkészültél, távolítsd el az erőforrásokat ezzel:

```powershell
terraform destroy -var="environment=dev"
```

# Terraform CI/CD Pipeline with Checkov

## Cél

Telepíts egy egyszerű Azure-infrastruktúrát egy újrafelhasználható Terraform modul segítségével Azure DevOps és egy védett CI/CD folyam közreműködésével. A lab a biztonságos Azure remote backend megfelelő sorrendjét, az Azure DevOpsben létrehozott Workload Identity Federation Service Connectiont, a szándékosan hibás Checkov ellenőrzést, a javítást, a sikeres validációt, a Terraform planet, a kontrollált applyt, az ellenőrzést és a tisztítást tanítja meg.

## Lab folyamata

1. Előfeltételek
2. Azure Storage remote backend
3. Azure DevOps service connection
4. Szándékosan hibás Checkov ellenőrzés a Storage Account TLS szabályára
5. Hallgatói javítás a `TLS1_2` értékre
6. Sikeres Checkov ellenőrzés
7. Terraform plan
8. Kontrollált apply környezet-engedélyezés után
9. Ellenőrzés
10. Tisztítás

---

## 1. Előfeltételek

Mielőtt elkezdenéd a labet, ellenőrizd a következőket:

- az Azure CLI telepítve van és a célzott előfizetéshez bejelentkezett
- létrehozva van az Azure DevOps szervezet és projekt
- létrehozva van a repository az Azure DevOpsben
- elérhető egy hostolt agent vagy ehhez hasonló környezet
- elérhetők a Terraform feladatok az Azure DevOpsben
- az Azure DevOpsben létrehozott `production` környezet megfelelő jóváhagyási kapuval van konfigurálva
- jogosultságod van Azure erőforráscsoportok és Storage Account létrehozására
- jogosultságod van Azure RBAC és Azure DevOps Service Connection konfigurálására

A lab nem hoz létre Azure-erőforrásokat Terraform apply vagy destroy parancsokból ebben a gyakorlatban. A beállító lépések először a szükséges közös backend erőforrásokat hozzák létre.

---

## 2. Közös backend és deployment resource groups

Provisionáld a közös backend erőforrásokat és a deployment resource groupet a pipeline lefutása előtt.

Használd ezeket a neveket:

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

## 4. Azure DevOps service connection

Az elsődleges, javasolt útvonal:

- Azure Resource Manager Service Connection
- Workload Identity Federation (WIF)
- nincs szükség hosszú életű client secretre

Készítsd el a Service Connectiont az Azure DevOps portálon, és ezt a nevet add neki:

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

Megjegyzések:

- A pipeline egy fail-first, remediate-second folyamattal demonstrálja a működést.
- A környezetre vonatkozó jóváhagyási kapu a `production` nevű Azure DevOps environmenten van konfigurálva.
- A jóváhagyások az Azure DevOpsben vannak konfigurálva, nem a YAML megjegyzésben.

---

## 9. Hallgatói munkafolyamat

### 1. lépés: Első futás

Commitold a szándékosan nem biztonságos modult, majd futtasd a pipeline-t.

Várt eredmény:

- a Checkov hibára fut a `CKV_AZURE_44` szabály miatt
- a pipeline megáll a plan lefutása előtt

### 2. lépés: Javítás

Módosítsd a `modules/simple_storage/main.tf` fájlban található erőforrást a következőről:

```hcl
min_tls_version = "TLS1_0"
```

erre:

```hcl
min_tls_version = "TLS1_2"
```

### 3. lépés: Második futás

A javítás után:

- a Checkov sikeresen lefut
- a Terraform plan lefut
- a `production` environment jóváhagyása szükséges
- a kontrollált apply telepíti a lab erőforrásait

### 4. lépés: Ellenőrzés

Ellenőrizd, hogy az Azure-erőforrások a `tf-day2-lab-rg` erőforráscsoportban jöttek-e létre, és hogy a Terraform state a megosztott backend Storage Accountben tárolódik.

---

## 10. Tisztítás

A tisztításnak meg kell különböztetnie a lab deployment erőforrásait és a megosztott backend erőforrásokat.

### A. Lab deployment erőforrások

Távolítsd el a `tf-day2-lab-rg` erőforráscsoporton belüli erőforrásokat, majd ha szükséges, töröld az erőforráscsoportot is.

Ez a lab deployment normál tisztítási folyamata.

### B. Megosztott backend erőforrások

Ne töröld a megosztott backend Storage Accountet, a containert vagy a state blobet a lab deployment erőforrásainak eltávolítása előtt.

Hagyd a backendet a helyén, amíg a lab teljesen le nem tisztult, és a state biztonságosan kezelhetővé nem válik.

### Tisztítás különböző eredmények esetén

- Sikeres apply után: távolítsd el a deployment erőforrásokat a `tf-day2-lab-rg` erőforráscsoportban, majd ha szükséges, töröld az erőforráscsoportot.
- Sikertelen pipeline után: nézd át a naplókat, javítsd a problémát, majd csak a lab erőforrásait tisztítsd meg.
- Kézi Azure-törlés után: ellenőrizd a state konzisztenciáját, majd folytasd a lab erőforrások tisztítását, mielőtt a backend state tárolását eltávolítanád.
- Részben elkészült deployment után: távolítsd el a létrehozott erőforráscsoport tartalmát, mielőtt bármely backend-state artefaktumot törölnél.

Ne adj hozzá alapértelmezetten védtelen destroy pipeline szakaszt. Ha a destroy szakasz benne marad, az explicit, kézi, és jóváhagyás által védett legyen.

---

## 11. Git és biztonsági előírások

- Soha ne commitolj valós hitelesítő adatokat vagy generált titkos kulcsokat.
- A példafájlok legyenek csak placeholder értékekkel ellátott minták.
- A commit előtt preferált a `git status` ellenőrzés.
- Használj explicit staginget például:

```bash
git status
git add main.tf azure-pipelines.yml modules/simple_storage/main.tf
git commit -m "Remediate storage TLS"
git push origin main
```

A lab során kerüld a széles körű `git add .` használatát.

---

## 12. Végső validációs ellenőrzőlista

Mielőtt lefuttatod a labet, ellenőrizd a következőket:

- a `terraform { backend "azurerm" {} }` szerepel a gyökér konfigurációban
- a `TF-SERVICE-CONNECTION` az elsődleges Azure DevOps kapcsolat neve
- a WIF a javasolt hitelesítési modell
- a `CKV_AZURE_44` a Checkov szabály a TLS gyakorlathoz
- a `min_tls_version = "TLS1_0"` a szándékosan induló állapot
- a `min_tls_version = "TLS1_2"` a javítás
- a `day2-lab.terraform.tfstate` mindenhol ugyanaz a state key
- a `production` környezet jóváhagyása konfigurálva van az Azure DevOpsben
- a tisztítás megkülönbözteti a megosztott backend erőforrásokat a deployment erőforrásoktól
- nincs Key Vault lab cél vagy kapcsolódó Key Vault utasítás ebben a Day 02 labben

Ez a lab a Terraform modulokra, az Azure Storage backendre, az Azure DevOpsra, a Checkovra, a plan/applyre és a tisztításra fókuszál.
