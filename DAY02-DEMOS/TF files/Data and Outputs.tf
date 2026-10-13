terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

# The resource group must already exist in Azure and the instructor must be authenticated to the correct subscription.
# 1. DATA (Data Source)
# We are fetching data of a resource group that already exists in Azure.
# This allows us to use its properties (e.g., location) without Terraform modifying or creating it.
data "azurerm_resource_group" "existing_rg" {
  name = "company-existing-resource-group"
}

# (A new resource that uses the information retrieved from the 'data' block)
resource "azurerm_virtual_network" "new_vnet" {
  name                = "new-virtual-network"
  address_space       = ["10.0.0.0/16"]
  # Here we reference the 'data' block to specify the location and resource group name:
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

# 2. OUTPUT
# After Terraform runs (apply), this block exports and displays the internal ID
# of the newly created network in the command line, which can be used by other systems or parent modules.
output "new_vnet_id" {
  description = "The unique ID of the newly created virtual network"
  value       = azurerm_virtual_network.new_vnet.id
}