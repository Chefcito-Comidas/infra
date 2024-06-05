terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.106.1"
    }
  }
}

provider "azurerm" {
   features {}
}

variable "location" {
  type = string
  default = "East US"
}

module "container_apps" {
  source = "./containerApps"
  rg_name = azurerm_resource_group.chefcito.name
  rg_id = azurerm_resource_group.chefcito.id
  location = var.location
}

resource "azurerm_resource_group" "chefcito" {
  name = "chefcito-rg"
  location = var.location 
} 

