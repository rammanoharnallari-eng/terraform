resource "kubernetes_namespace" "data" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = var.app_namespace
  }
}

resource "random_password" "mongo_root" {
  length  = 20
  special = true
}

resource "helm_release" "mongodb" {
  name       = "mongodb"
  namespace  = kubernetes_namespace.data.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"

  values = [yamlencode({
    architecture = "replicaset"
    replicaCount = 3
    auth = {
      enabled      = true
      rootUser     = "root"
      rootPassword = random_password.mongo_root.result
      username     = var.app_user
      password     = var.app_password
      database     = var.app_database
    }
    persistence = {
      enabled = true
      size    = "10Gi"
    }
    replicaSetName = "rs0"
    podDisruptionBudget = {
      enabled     = true
      minAvailable = 1
    }
    podAntiAffinityPreset = "hard"
    topologySpreadConstraints = [{
      maxSkew           = 1
      topologyKey       = "topology.kubernetes.io/zone"
      whenUnsatisfiable = "DoNotSchedule"
      labelSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mongodb"
        }
      }
    }]
  })]
}
