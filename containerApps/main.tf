terraform {
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

variable "rg_name" {
  type = string
  nullable = false
}

variable "rg_id" {
  type = string
  nullable = false
}

variable "acr_name" {
  type = string
  default = "chefcitoacr"
}

variable "app_env_name" {
  type = string
  default = "chefcito-app-env"
}

variable "gateway_image" {
  type = string
  default = "gateway:latest"
}

resource "azurerm_container_registry" "acr" {
  sku = "Standard"
  location = var.location
  resource_group_name = var.rg_name
  name = var.acr_name
  anonymous_pull_enabled = false
  admin_enabled = true
}

resource "azurerm_container_app_environment" "app_env" {
  name = var.app_env_name
  location = var.location
  resource_group_name = var.rg_name
  workload_profile {
    name = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count = 0
    maximum_count = 1
  }
}

resource "azurerm_container_app" "gateway_app" {
  name = "gateway"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name = var.rg_name
  revision_mode = "Single"
  secret {
    name = "password"
    value = azurerm_container_registry.acr.admin_password
  }
  registry {
    server = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "password"
  }
  template {
    container {
      name = "gateway-service"
      image = "${azurerm_container_registry.acr.login_server}/${var.gateway_image}"
      cpu = 0.25
      memory = "0.5Gi"
      
    }
  }
  ingress {
    external_enabled = true
    target_port = 80
    traffic_weight {
      latest_revision = true
      percentage = 100
    }
  }
}

