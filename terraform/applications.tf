# Ждем, пока кластер будет готов
resource "time_sleep" "wait_for_kubernetes" {
  depends_on = [ssh_resource.install_kubernetes_workers]
  create_duration = "30s"
}

# Копируем конфиг kubectl с мастер-ноды
resource "ssh_resource" "get_kube_config" {
  depends_on = [time_sleep.wait_for_kubernetes]
  
  host        = var.master_ip
  user        = var.ssh_user
  private_key = file(var.ssh_private_key)

  commands = [
    "sudo cat /etc/kubernetes/admin.conf"
  ]
}

# Создаем локальный файл с конфигом kubectl
resource "local_file" "kube_config" {
  content  = ssh_resource.get_kube_config.result
  filename = "${path.module}/kubeconfig"
}

# Настраиваем провайдер kubernetes
provider "kubernetes" {
  config_path = local_file.kube_config.filename
}

# Создаем namespace для приложений
resource "kubernetes_namespace" "apps" {
  depends_on = [local_file.kube_config]
  
  metadata {
    name = "apps"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for namespace to be ready
resource "time_sleep" "wait_for_namespace" {
  depends_on = [kubernetes_namespace.apps]
  create_duration = "10s"
}

# ServiceAccount для Traefik
resource "kubernetes_service_account" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
}

# ClusterRole для Traefik
resource "kubernetes_cluster_role" "traefik" {
  metadata {
    name = "traefik"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "secrets", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses", "ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["traefik.io", "traefik.containo.us"]
    resources  = [
      "ingressroutes",
      "ingressroutetcps",
      "ingressrouteudps",
      "middlewares",
      "middlewaretcps",
      "tlsoptions",
      "tlsstores",
      "serverstransports",
      "serverstransporttcps",
      "traefikservices",
    ]
    verbs      = ["get", "list", "watch"]
  }

  # Добавляем права на создание и обновление
  rule {
    api_groups = ["traefik.io", "traefik.containo.us"]
    resources  = [
      "ingressroutes/status",
      "ingressroutetcps/status",
      "ingressrouteudps/status",
      "middlewares/status",
      "middlewaretcps/status",
      "serverstransports/status",
      "serverstransporttcps/status"
    ]
    verbs      = ["get", "list", "watch", "update", "create"]
  }
}

# ClusterRoleBinding для Traefik
resource "kubernetes_cluster_role_binding" "traefik" {
  metadata {
    name = "traefik"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.traefik.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.traefik.metadata[0].name
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
}

# Разворачиваем Traefik
resource "kubernetes_deployment" "traefik" {
  depends_on = [time_sleep.wait_for_crds]

  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "traefik"
      }
    }

    template {
      metadata {
        labels = {
          app = "traefik"
        }
      }

      spec {
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          image = "traefik:v3.3.3"
          name  = "traefik"

          args = [
            "--api.insecure=true",
            "--providers.kubernetesingress",
            "--providers.kubernetescrd",
            "--log.level=DEBUG",
            "--ping=true",
            "--entrypoints.web.address=:80",
            "--entrypoints.web.forwardedHeaders.insecure",
            "--accesslog=true"
          ]

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/ping"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds       = 5
          }

          port {
            name           = "web"
            container_port = 80
          }

          port {
            name           = "dashboard"
            container_port = 8080
          }
        }

        service_account_name = kubernetes_service_account.traefik.metadata[0].name
      }
    }
  }
}

# Сервис для Traefik
resource "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "traefik"
    }

    port {
      port        = 80
      target_port = "web"
      name        = "web"
      node_port   = 30080
    }

    port {
      port        = 8080
      target_port = "dashboard"
      name        = "dashboard"
      node_port   = 30081
    }

    type = "NodePort"
  }
}

# Разворачиваем FlareSolverr
resource "kubernetes_deployment" "flaresolverr" {
  depends_on = [kubernetes_namespace.apps]

  metadata {
    name      = "flaresolverr"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flaresolverr"
      }
    }

    template {
      metadata {
        labels = {
          app = "flaresolverr"
        }
      }

      spec {
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          image = "ghcr.io/flaresolverr/flaresolverr:latest"
          name  = "flaresolverr"

          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8191
            }
            initial_delay_seconds = 30
            period_seconds       = 10
          }

          port {
            container_port = 8191
          }
        }
      }
    }
  }
}

# Сервис для FlareSolverr
resource "kubernetes_service" "flaresolverr" {
  metadata {
    name      = "flaresolverr"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    selector = {
      app = "flaresolverr"
    }

    port {
      port        = 8191
      target_port = 8191
    }
  }
}

# HPA для FlareSolverr
resource "kubernetes_horizontal_pod_autoscaler_v2" "flaresolverr" {
  metadata {
    name      = "flaresolverr"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.flaresolverr.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# IngressRoute для FlareSolverr
resource "kubernetes_manifest" "flaresolverr_route" {
  depends_on = [
    kubernetes_deployment.traefik, 
    time_sleep.wait_for_crds,
    kubernetes_service.flaresolverr
  ]

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "flaresolverr-route"
      namespace = kubernetes_namespace.apps.metadata[0].name
    }
    spec = {
      entryPoints = ["web"]
      routes = [
        {
          match = "PathPrefix(`/v1`)"
          kind  = "Rule"
          services = [
            {
              name = kubernetes_service.flaresolverr.metadata[0].name
              port = 8191
            }
          ]
        }
      ]
    }
  }
}
