resource "kubernetes_manifest" "a2024_ingress" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "Ingress"
    "metadata" = {
      "annotations" = {
        "nginx.ingress.kubernetes.io/rewrite-target" = "/"
        "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
      }
      "name" = "a2024-ingress"
      "namespace" = "a2024"
    }
    "spec" = {
      "ingressClassName" = "nginx"
      "rules" = [
        {
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "a2024-service"
                    "port" = {
                      "number" = 1741
                    }
                  }
                }
                "path" = "/"
                "pathType" = "Prefix"
              },
            ]
          }
        },
      ]
    }
  }
}
