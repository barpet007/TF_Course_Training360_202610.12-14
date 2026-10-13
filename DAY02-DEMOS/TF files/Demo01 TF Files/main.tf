provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment must be either dev or prod."
  }
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "subnets" {
  type = map(string)

  default = {
    frontend = "10.0.1.0/24"
    backend   = "10.0.2.0/24"
  }
}

data "azurerm_client_config" "current" {}

output "current_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_resource_group" "demo" {
  name     = "advanced-demo-${var.environment}-rg"
  location = "West Europe"

  tags = merge(
    { Source = "Terraform" },
    { Env = var.environment }
  )
}

resource "azurerm_virtual_network" "vnet" {
  for_each = var.subnets

  name                = "vnet-${each.key}"
  address_space       = [each.value]
  location            = azurerm_resource_group.demo.location
  resource_group_name = azurerm_resource_group.demo.name
}