resource "kubernetes_manifest" "statefulset_a2024_mongo_deployment" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "StatefulSet"
    "metadata" = {
      "labels" = {
        "app" = "mongodb"
      }
      "name" = "mongo-deployment"
      "namespace" = "a2024"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "mongodb"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "mongodb"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "mongo:latest"
              "name" = "elixir-mongo"
              "ports" = [
                {
                  "containerPort" = 27017
                },
              ]
              "resources" = {}
            },
          ]
          "restartPolicy" = "Always"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_a2024_mongodb_service" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "mongodb-service"
      "namespace" = "a2024"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 27017
          "protocol" = "TCP"
          "targetPort" = 27017
        },
      ]
      "selector" = {
        "app" = "mongodb"
      }
    }
  }
}
