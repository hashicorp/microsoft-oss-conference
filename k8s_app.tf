resource "kubernetes_service" "gophersearch" {
  metadata {
    name = "gophersearch"
  }

  spec {
    selector {
      app = "${kubernetes_pod.gophersearch.metadata.0.labels.app}"
    }

    session_affinity = "ClientIP"

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_pod" "gophersearch" {
  metadata {
    name = "gophersearch"

    labels {
      app = "gophersearch"
    }
  }

  spec {
    container {
      image = "nicholasjackson/gophersearch:latest"
      name  = "gophersearch"

      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_user}@${azurerm_postgresql_server.gophersearch.name}:${random_string.db_password.result}@${azurerm_postgresql_server.gophersearch.fqdn}:5432/gophersearch?sslmode=disable"
      }

      env {
        name  = "GO_ENV"
        value = "production"
      }
    }
  }
}
