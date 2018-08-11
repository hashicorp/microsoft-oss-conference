/*
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
      port        = 3000
      target_port = 80
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
    }
  }
}
*/

