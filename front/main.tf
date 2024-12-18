terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.106.1"
    }
  }
}


variable "location" {
  type    = string
  default = "East US 2"
}

variable "rg_name" {
  type     = string
  nullable = false
}

variable "name" {
  type = string
  nullable = false
}

resource "azurerm_static_web_app" "front" {
  name = var.name
  resource_group_name = var.rg_name
  location = var.location
}


