terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.106.1"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "East US"
}

variable "firebase_key" {
  type     = string
  nullable = false
}

variable "db_password" {
  type     = string
  nullable = false
}

variable "db_username" {
  type     = string
  nullable = false
}

variable "vertex_key" {
  type     = string
  nullable = false
}

variable "vertex_key_id" {
  type     = string
  nullable = false
}

variable "twilio_key" {
  type     = string
  nullable = false
}

variable "twilio_key_id" {
  type     = string
  nullable = false
}

module "container_apps" {
  source        = "./containerApps"
  rg_name       = azurerm_resource_group.chefcito.name
  rg_id         = azurerm_resource_group.chefcito.id
  location      = var.location
  firebase_key  = var.firebase_key
  db_password   = var.db_password
  db_username   = var.db_username
  vertex_key    = var.vertex_key
  vertex_key_id = var.vertex_key_id
  twilio_key    = var.twilio_key
  twilio_key_id = var.twilio_key_id
}

module "frontend" {
  source  = "./front"
  rg_name = azurerm_resource_group.chefcito.name
  name    = "chefcito-web"
}

module "book_front" {
  source  = "./front"
  rg_name = azurerm_resource_group.chefcito.name
  name    = "chefcito-booking"
}

resource "azurerm_resource_group" "chefcito" {
  name     = "chefcito-rg"
  location = var.location
}

