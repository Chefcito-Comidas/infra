provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

variable "db_string" {
  type = string
  default = "POSTGRE_CONN_STRING"

}

variable "mongo_string" {
  type = string
  default = "MONGO_CONN_STRING"
}

variable "twilio_sid" {
  type = string
  default = "SomeValue"
}

variable "twilio_token" {
  type = string
  default = "SomeValue"
}

variable "firebase_key" {
  type = string
  default = "Firebase_api_key"
}

variable "vertex_key" {
  type = string
  default = "VERTEX_BASE64_STRING"
}

variable "vertex_key_id" {
  type = string
  default = "VERTEX_KEY_ID"
}

resource "kubernetes_namespace" "chefcito" {
  metadata {
    name = "chefcito-namespace"
  }
}

module "users" {
  source = "./deployment"
  deployment_name = "users"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "users"}
  match_labels = {service: "users"}
  deployment_labels = {service: "users"}
  container_name = "users"
  container_image = "service-users:latest"
  env = {"API_KEY": var.firebase_key,
         "DB_STRING": var.db_string,        
         "COMMUNICATIONS": module.communications.name,
         "PROTO": "http://"
  }
}

module "gateway" {
  source = "./deployment"
  deployment_name = "gateway"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "gateway"}
  match_labels = {service: "gateway"}
  deployment_labels = {service: "gateway"}
  container_name = "gateway"
  container_image = "service-gateway:latest"
  env = {
    "USERS": module.users.name,
    "VENUES": module.venues.name,
    "RESERVATIONS": module.reservations.name,
    "POINTS": module.points.name,
    "DEV": false
  }
}


module "reservations" {
  source = "./deployment"
  deployment_name = "reservations"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "reservations"}
  match_labels = {service: "reservations"}
  deployment_labels = {service: "reservations"}
  container_name = "reservations"
  container_image = "service-reservations:latest"
  env = {
    "DB_STRING": var.db_string,
    "VENUES": module.venues.name,
    "OPINIONS": module.opinions.name,
    "STATS": module.stats.name,
    "POINTS": module.points.name,
    "USERS": module.users.name,
    "PROTO": "http://"
  }
}

module "venues" {
  source = "./deployment"
  deployment_name = "venues"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "venues"}
  match_labels = {service: "venues"}
  deployment_labels = {service: "venues"}
  container_name = "venues"
  container_image = "service-venues:latest"
  env = {
    "DB_STRING": var.db_string
  }
}


module "opinions" {
  source = "./deployment"
  deployment_name = "opinions"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "opinions"}
  match_labels = {service: "opinions"}
  deployment_labels = {service: "opinions"}
  container_name = "opinions"
  container_image = "service-opinions:latest"
  env = {
    "CONN_STRING": var.mongo_string,
    "SUMMARIES": module.summaries.name,
    "PROTO": "http://"
  }
}


module "stats" {
  source = "./deployment"
  deployment_name = "stats"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "stats"}
  match_labels = {service: "stats"}
  deployment_labels = {service: "stats"}
  container_name = "stats"
  container_image = "service-stats:latest"
  env = {
    "MONGO_STRING": var.mongo_string
  }
}


module "communications" {
  source = "./deployment"
  deployment_name = "communications"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "communications"}
  match_labels = {service: "communications"}
  deployment_labels = {service: "communications"}
  container_name = "communications"
  container_image = "service-communications:latest"
  env = {"DB_STRING": var.db_string,
         "TWILIO_SID": var.twilio_sid,
         "TWILIO_TOKEN": var.twilio_token
  }
}


module "summaries" {
  source = "./deployment"
  deployment_name = "summaries"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "summaries"}
  match_labels = {service: "summaries"}
  deployment_labels = {service: "summaries"}
  container_name = "summaries"
  container_image = "service-summaries:latest"
  env = {
    "CONN_STRING": var.mongo_string,
    "KEY_ID": var.vertex_key_id,
    "KEY": var.vertex_key,
    "DEV": true
  }
}


module "points" {
  source = "./deployment"
  deployment_name = "points"
  namespace = kubernetes_namespace.chefcito.id
  labels = {service: "points"}
  match_labels = {service: "points"}
  deployment_labels = {service: "points"}
  container_name = "points"
  container_image = "service-points:latest"
  env = {
    "CONN_STRING": var.db_string
  }
}


