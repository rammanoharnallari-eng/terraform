locals {
  mongo_seed_hosts = [
    "mongodb-0.mongodb-headless.data.svc.cluster.local:27017",
    "mongodb-1.mongodb-headless.data.svc.cluster.local:27017",
    "mongodb-2.mongodb-headless.data.svc.cluster.local:27017",
  ]

  mongo_url = "mongodb://${var.mongo_app_user}:${var.mongo_app_password}@${join(",", local.mongo_seed_hosts)}/${var.mongo_app_database}?replicaSet=rs0&authSource=${var.mongo_app_database}"
}

resource "kubernetes_secret" "app_conn" {
  metadata {
    name      = "app-conn"
    namespace = var.namespace
  }

  data = {
    MONGODB_URL = local.mongo_url
  }

  type = "Opaque"
}

resource "helm_release" "app" {
  name      = "swimlane-app"
  namespace = var.namespace
  chart     = var.chart_path

  values = [yamlencode({
    image = {
      repository = var.image_repository
      tag        = var.image_tag
    }
  })]

  depends_on = [kubernetes_secret.app_conn]
}
