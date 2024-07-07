terraform {
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

data "azurerm_client_config" "current" {}

variable "location" {
  type    = string
  default = "East US"
}

variable "rg_name" {
  type     = string
  nullable = false
}

variable "rg_id" {
  type     = string
  nullable = false
}

variable "acr_name" {
  type    = string
  default = "chefcitoacr"
}

variable "app_env_name" {
  type    = string
  default = "chefcito-app-env"
}

variable "gateway_image" {
  type    = string
  default = "gateway:latest"
}

variable "users_image" {
  type    = string
  default = "users:latest"
}

variable "reservations_image" {
  type = string
  default = "reservations:latest"
}

variable "venues_image" {
  type = string
  default = "venues:latest"
}

variable "firebase_key" {
  type     = string
  nullable = false
}

variable "db_password" {
  type = string
  nullable = false
}

variable "db_username" {
  type = string
  nullable = false
}

resource "azurerm_container_registry" "acr" {
  sku                    = "Standard"
  location               = var.location
  resource_group_name    = var.rg_name
  name                   = var.acr_name
  anonymous_pull_enabled = false
  admin_enabled          = true
}

resource "azurerm_container_app_environment" "app_env" {
  name                = var.app_env_name
  location            = var.location
  resource_group_name = var.rg_name
  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 1
  }
}

resource "azurerm_key_vault" "chefcito_vault" {
  name = "chefcitovault"

  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Get",
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}


resource "azurerm_key_vault_secret" "users_db_string" {
  name         = "USERSDBSTRING"
  value        = "postgresql://${azurerm_postgresql_flexible_server.postgre_server.administrator_login}:${azurerm_postgresql_flexible_server.postgre_server.administrator_password}@${azurerm_postgresql_flexible_server.postgre_server.fqdn}/${azurerm_postgresql_flexible_server_database.users_base.name}"
  key_vault_id = azurerm_key_vault.chefcito_vault.id
}

resource "azurerm_key_vault_secret" "firebase_key" {
  name         = "firebasekey"
  value        = var.firebase_key
  key_vault_id = azurerm_key_vault.chefcito_vault.id
}

resource "azurerm_postgresql_flexible_server" "postgre_server" {
  name                   = "chefcito-users-server"
  resource_group_name    = var.rg_name
  location               = var.location
  version                = "16"
  sku_name               = "B_Standard_B1ms"
  administrator_login    = var.db_username
  administrator_password = var.db_password 
  zone                   = "2"
}

resource "azurerm_postgresql_flexible_server_database" "users_base" {
  name       = "chefcitousersbase"
  collation  = "en_US.utf8"
  charset    = "UTF8"
  server_id  = azurerm_postgresql_flexible_server.postgre_server.id
  depends_on = [azurerm_postgresql_flexible_server.postgre_server]
}

resource "azurerm_container_app" "gateway_app" {
  name                         = "gateway"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = var.rg_name
  revision_mode                = "Single"
  secret {
    name  = "password"
    value = azurerm_container_registry.acr.admin_password
  }
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "password"
  }
  template {
    container {
      name   = "gateway-service"
      image  = "${azurerm_container_registry.acr.login_server}/${var.gateway_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name  = "USERS"
        value = azurerm_container_app.users.ingress[0].fqdn
      }
      env {
        name = "RESERVATIONS"
        value = azurerm_container_app.reservations.ingress[0].fqdn
      }
      env {
        name = "VENUES"
        value = azurerm_container_app.venues.ingress[0].fqdn
      }
      env {
        name  = "DEV"
        value = false
      }
      env {
        name = "PROTO"
        value = "https://"
      }
    }
  }
  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "users" {
  name                         = "users"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = var.rg_name
  revision_mode                = "Single"
  secret {
    name  = "password"
    value = azurerm_container_registry.acr.admin_password
  }
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "password"
  }
  secret {
    name  = "db-string"
    value = azurerm_key_vault_secret.users_db_string.value
  }
  secret {
    name  = "firebase-key"
    value = azurerm_key_vault_secret.firebase_key.value
  }
  template {
    container {
      name   = "users-service"
      image  = "${azurerm_container_registry.acr.login_server}/${var.users_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name        = "DB_STRING"
        secret_name = "db-string"
      }
      env {
        name        = "API_KEY"
        secret_name = "firebase-key"
      }
    }
  }
  ingress {
    target_port = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "reservations" {
  name                         = "reservations"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = var.rg_name
  revision_mode                = "Single"
  secret {
    name  = "password"
    value = azurerm_container_registry.acr.admin_password
  }
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "password"
  }
  secret {
    name  = "db-string"
    value = azurerm_key_vault_secret.users_db_string.value
  }
  template {
    container {
      name   = "reservations-service"
      image  = "${azurerm_container_registry.acr.login_server}/${var.reservations_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name        = "DB_STRING"
        secret_name = "db-string"
      }
    }
  }
  ingress {
    target_port = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "venues" {
  name                         = "venues"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = var.rg_name
  revision_mode                = "Single"
  secret {
    name  = "password"
    value = azurerm_container_registry.acr.admin_password
  }
  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "password"
  }
  secret {
    name  = "db-string"
    value = azurerm_key_vault_secret.users_db_string.value
  }
  template {
    container {
      name   = "venues-service"
      image  = "${azurerm_container_registry.acr.login_server}/${var.venues_image}"
      cpu    = 0.25
      memory = "0.5Gi"
      env {
        name        = "DB_STRING"
        secret_name = "db-string"
      }
    }
  }
  ingress {
    target_port = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

