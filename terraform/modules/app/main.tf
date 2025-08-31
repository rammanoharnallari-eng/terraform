locals {
  # Updated to use the simple MongoDB service
  mongo_url = "mongodb://${var.mongo_app_user}:${var.mongo_app_password}@mongodb-simple.data.svc.cluster.local:27017/${var.mongo_app_database}?authSource=admin"
}

resource "kubernetes_secret" "app_conn" {
  metadata {
    name      = "app-conn"
    namespace = var.namespace
  }
  data = { MONGODB_URL = local.mongo_url }
  type = "Opaque"
}

# Use a simple Kubernetes deployment instead of Helm chart
resource "kubernetes_deployment" "app" {
  metadata {
    name      = "swimlane-app-v2"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "swimlane-app-v2"
      }
    }

    template {
      metadata {
        labels = {
          app = "swimlane-app-v2"
        }
      }

      spec {
        container {
          name  = "app"
          image = "${var.image_repository}:${var.image_tag}"

          port {
            container_port = 3000
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.app_conn.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          # Simplified health checks
          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 60
            timeout_seconds       = 10
            failure_threshold     = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.app_conn]
}

resource "kubernetes_service" "app" {
  metadata {
    name      = "swimlane-app-v2"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "swimlane-app-v2"
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}
