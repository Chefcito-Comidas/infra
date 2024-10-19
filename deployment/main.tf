variable "config_path" {
  type = string
  default = "~/.kube/config"
}

variable "config_context" {
  type = string
  default = "minikube"
}

provider "kubernetes" {
  config_path = var.config_path
  config_context = var.config_context
}

variable "deployment_name" {
  type = string
  nullable = false
}

variable "namespace" {
  type = string
  nullable = false
}

variable "labels" {
  type = map
  nullable = false
}

variable "match_labels" {
  type = map
  nullable = false
}

variable "deployment_labels" {
  type = map
  nullable = false
}

variable "container_name" {
  type = string
  nullable = false
}

variable "container_image" {
  type = string
  nullable = false
}

variable "pull_policy" {
  type = string
  default = "Never"
}

variable "env" {
  type = map
  nullable = true
  default = {}
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name = "${var.deployment_name}-deployment"
    namespace = var.namespace
    labels = var.labels
  }
  spec {
    selector {
      match_labels = var.match_labels
    }
    template {
      metadata {
        name = "${var.deployment_name}-pod"
        labels = var.deployment_labels
        
      }
      spec {
        container {
          name = var.container_name
          image = var.container_image
          image_pull_policy = var.pull_policy
          dynamic "env" {
            for_each = var.env
            content {
              name = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "port" {
  metadata {
    name = "${var.deployment_name}-service"
    namespace = var.namespace
    labels = var.labels
  }
  spec {
    selector = var.match_labels
    type = "NodePort"
    port {
      port = 80
      target_port = 80
    }
  }
}

output "name" {
  value = "${kubernetes_service.port.metadata[0].name}.${var.namespace}.svc.cluster.local"
}
