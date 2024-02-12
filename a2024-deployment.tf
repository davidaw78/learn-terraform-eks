resource "kubernetes_manifest" "namespace_a2024" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Namespace"
    "metadata" = {
      "name" = "a2024"
    }
  }
}

resource "kubernetes_manifest" "deployment_a2024_a2024_deployment" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "labels" = {
        "app" = "a2024"
      }
      "name" = "a2024-deployment"
      "namespace" = "a2024"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "a2024"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "a2024"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name" = "externalhost"
                  "value" = "a80aa0e285bbe4495a414c623d78f393-917726230.us-east-1.elb.amazonaws.com"
                },
                {
                  "name" = "externalport"
                  "value" = "80"
                },
                {
                  "name" = "externalprotocol"
                  "value" = "http:"
                },
                {
                  "name" = "mongourl"
                  "value" = "mongodb://mongodb-service:27017"
                },
              ]
              "image" = "elixirtech/elixir-ambience"
              "name" = "a2024"
              "ports" = [
                {
                  "containerPort" = 1740
                },
              ]
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_a2024_a2024_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "a2024-service"
      "namespace" = "a2024"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 1741
          "protocol" = "TCP"
          "targetPort" = 1740
        },
      ]
      "selector" = {
        "app" = "a2024"
      }
    }
  }
}
