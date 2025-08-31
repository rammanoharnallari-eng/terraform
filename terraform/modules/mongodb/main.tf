resource "kubernetes_namespace" "data" {
  metadata { name = var.namespace }
}

resource "kubernetes_namespace" "apps" {
  metadata { name = var.app_namespace }
}

resource "random_password" "mongo_root" {
  length  = 20
  special = true
}

# Use a simple MongoDB deployment with emptyDir storage
resource "kubernetes_deployment" "mongodb" {
  metadata {
    name      = "mongodb-simple"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongodb-simple"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb-simple"
        }
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:7.0"

          port {
            container_port = 27017
          }

          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "root"
          }

          env {
            name  = "MONGO_INITDB_ROOT_PASSWORD"
            value = random_password.mongo_root.result
          }

          env {
            name  = "MONGO_INITDB_DATABASE"
            value = var.app_database
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          volume_mount {
            name       = "mongodb-storage"
            mount_path = "/data/db"
          }
        }

        volume {
          name = "mongodb-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb-simple"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  spec {
    selector = {
      app = "mongodb-simple"
    }

    port {
      port        = 27017
      target_port = 27017
    }
  }
}

output "namespace"     { value = kubernetes_namespace.data.metadata[0].name }
output "app_namespace" { value = kubernetes_namespace.apps.metadata[0].name }
