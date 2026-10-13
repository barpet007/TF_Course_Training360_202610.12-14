# Fejlett moduláris Terraform lab

## Cél

Telepíts Azure-infrastruktúrát helyben Terraformrel. Ez a lab bemutatja:

- input validation
- `for_each`
- `depends_on`
- újrafelhasználható modulokat

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
