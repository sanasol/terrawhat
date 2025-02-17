# Установка CRD для Traefik
resource "kubernetes_manifest" "traefik_ingressroute_crd" {
  count = var.install_traefik_crds ? 1 : 0  # Only create if explicitly enabled
  manifest = {
    "apiVersion" = "apiextensions.k8s.io/v1"
    "kind" = "CustomResourceDefinition"
    "metadata" = {
      "annotations" = {
        "controller-gen.kubebuilder.io/version" = "v0.16.1"
      }
      "name" = "ingressroutes.traefik.io"
    }
    "spec" = {
      "group" = "traefik.io"
      "names" = {
        "kind" = "IngressRoute"
        "listKind" = "IngressRouteList"
        "plural" = "ingressroutes"
        "singular" = "ingressroute"
      }
      "scope" = "Namespaced"
      "versions" = [
        {
          "name" = "v1alpha1"
          "schema" = {
            "openAPIV3Schema" = {
              "description" = "IngressRoute is the CRD implementation of a Traefik HTTP Router."
              "properties" = {
                "apiVersion" = {
                  "description" = <<-EOT
                  APIVersion defines the versioned schema of this representation of an object.
                  Servers should convert recognized schemas to the latest internal value, and
                  may reject unrecognized values.
                  More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
                  EOT
                  "type" = "string"
                }
                "kind" = {
                  "description" = <<-EOT
                  Kind is a string value representing the REST resource this object represents.
                  Servers may infer this from the endpoint the client submits requests to.
                  Cannot be updated.
                  In CamelCase.
                  More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
                  EOT
                  "type" = "string"
                }
                "metadata" = {
                  "type" = "object"
                }
                "spec" = {
                  "description" = "IngressRouteSpec defines the desired state of IngressRoute."
                  "properties" = {
                    "entryPoints" = {
                      "description" = <<-EOT
                      EntryPoints defines the list of entry point names to bind to.
                      Entry points have to be configured in the static configuration.
                      More info: https://doc.traefik.io/traefik/v3.1/routing/entrypoints/
                      Default: all.
                      EOT
                      "items" = {
                        "type" = "string"
                      }
                      "type" = "array"
                    }
                    "routes" = {
                      "description" = "Routes defines the list of routes."
                      "items" = {
                        "description" = "Route holds the HTTP route configuration."
                        "properties" = {
                          "kind" = {
                            "description" = <<-EOT
                            Kind defines the kind of the route.
                            Rule is the only supported kind.
                            EOT
                            "enum" = [
                              "Rule",
                            ]
                            "type" = "string"
                          }
                          "match" = {
                            "description" = <<-EOT
                            Match defines the router's rule.
                            More info: https://doc.traefik.io/traefik/v3.1/routing/routers/#rule
                            EOT
                            "type" = "string"
                          }
                          "middlewares" = {
                            "description" = <<-EOT
                            Middlewares defines the list of references to Middleware resources.
                            More info: https://doc.traefik.io/traefik/v3.1/routing/providers/kubernetes-crd/#kind-middleware
                            EOT
                            "items" = {
                              "description" = "MiddlewareRef is a reference to a Middleware resource."
                              "properties" = {
                                "name" = {
                                  "description" = "Name defines the name of the referenced Middleware resource."
                                  "type" = "string"
                                }
                                "namespace" = {
                                  "description" = "Namespace defines the namespace of the referenced Middleware resource."
                                  "type" = "string"
                                }
                              }
                              "required" = [
                                "name",
                              ]
                              "type" = "object"
                            }
                            "type" = "array"
                          }
                          "priority" = {
                            "description" = <<-EOT
                            Priority defines the router's priority.
                            More info: https://doc.traefik.io/traefik/v3.1/routing/routers/#priority
                            EOT
                            "type" = "integer"
                          }
                          "services" = {
                            "description" = <<-EOT
                            Services defines the list of Service.
                            It can contain any combination of TraefikService and/or reference to a Kubernetes Service.
                            EOT
                            "items" = {
                              "description" = "Service defines an upstream HTTP service to proxy traffic to."
                              "properties" = {
                                "healthCheck" = {
                                  "description" = "Healthcheck defines health checks for ExternalName services."
                                  "properties" = {
                                    "followRedirects" = {
                                      "description" = <<-EOT
                                      FollowRedirects defines whether redirects should be followed during the health check calls.
                                      Default: true
                                      EOT
                                      "type" = "boolean"
                                    }
                                    "headers" = {
                                      "additionalProperties" = {
                                        "type" = "string"
                                      }
                                      "description" = "Headers defines custom headers to be sent to the health check endpoint."
                                      "type" = "object"
                                    }
                                    "hostname" = {
                                      "description" = "Hostname defines the value of hostname in the Host header of the health check request."
                                      "type" = "string"
                                    }
                                    "interval" = {
                                      "anyOf" = [
                                        {
                                          "type" = "integer"
                                        },
                                        {
                                          "type" = "string"
                                        },
                                      ]
                                      "description" = <<-EOT
                                      Interval defines the frequency of the health check calls.
                                      Default: 30s
                                      EOT
                                      "x-kubernetes-int-or-string" = true
                                    }
                                    "method" = {
                                      "description" = "Method defines the healthcheck method."
                                      "type" = "string"
                                    }
                                    "mode" = {
                                      "description" = <<-EOT
                                      Mode defines the health check mode.
                                      If defined to grpc, will use the gRPC health check protocol to probe the server.
                                      Default: http
                                      EOT
                                      "type" = "string"
                                    }
                                    "path" = {
                                      "description" = "Path defines the server URL path for the health check endpoint."
                                      "type" = "string"
                                    }
                                    "port" = {
                                      "description" = "Port defines the server URL port for the health check endpoint."
                                      "type" = "integer"
                                    }
                                    "scheme" = {
                                      "description" = "Scheme replaces the server URL scheme for the health check endpoint."
                                      "type" = "string"
                                    }
                                    "status" = {
                                      "description" = "Status defines the expected HTTP status code of the response to the health check request."
                                      "type" = "integer"
                                    }
                                    "timeout" = {
                                      "anyOf" = [
                                        {
                                          "type" = "integer"
                                        },
                                        {
                                          "type" = "string"
                                        },
                                      ]
                                      "description" = <<-EOT
                                      Timeout defines the maximum duration Traefik will wait for a health check request before considering the server unhealthy.
                                      Default: 5s
                                      EOT
                                      "x-kubernetes-int-or-string" = true
                                    }
                                  }
                                  "type" = "object"
                                }
                                "kind" = {
                                  "description" = "Kind defines the kind of the Service."
                                  "enum" = [
                                    "Service",
                                    "TraefikService",
                                  ]
                                  "type" = "string"
                                }
                                "name" = {
                                  "description" = <<-EOT
                                  Name defines the name of the referenced Kubernetes Service or TraefikService.
                                  The differentiation between the two is specified in the Kind field.
                                  EOT
                                  "type" = "string"
                                }
                                "namespace" = {
                                  "description" = "Namespace defines the namespace of the referenced Kubernetes Service or TraefikService."
                                  "type" = "string"
                                }
                                "nativeLB" = {
                                  "description" = <<-EOT
                                  NativeLB controls, when creating the load-balancer,
                                  whether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.
                                  The Kubernetes Service itself does load-balance to the pods.
                                  By default, NativeLB is false.
                                  EOT
                                  "type" = "boolean"
                                }
                                "nodePortLB" = {
                                  "description" = <<-EOT
                                  NodePortLB controls, when creating the load-balancer,
                                  whether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.
                                  It allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.
                                  By default, NodePortLB is false.
                                  EOT
                                  "type" = "boolean"
                                }
                                "passHostHeader" = {
                                  "description" = <<-EOT
                                  PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.
                                  By default, passHostHeader is true.
                                  EOT
                                  "type" = "boolean"
                                }
                                "port" = {
                                  "anyOf" = [
                                    {
                                      "type" = "integer"
                                    },
                                    {
                                      "type" = "string"
                                    },
                                  ]
                                  "description" = <<-EOT
                                  Port defines the port of a Kubernetes Service.
                                  This can be a reference to a named port.
                                  EOT
                                  "x-kubernetes-int-or-string" = true
                                }
                                "responseForwarding" = {
                                  "description" = "ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client."
                                  "properties" = {
                                    "flushInterval" = {
                                      "description" = <<-EOT
                                      FlushInterval defines the interval, in milliseconds, in between flushes to the client while copying the response body.
                                      A negative value means to flush immediately after each write to the client.
                                      This configuration is ignored when ReverseProxy recognizes a response as a streaming response;
                                      for such responses, writes are flushed to the client immediately.
                                      Default: 100ms
                                      EOT
                                      "type" = "string"
                                    }
                                  }
                                  "type" = "object"
                                }
                                "scheme" = {
                                  "description" = <<-EOT
                                  Scheme defines the scheme to use for the request to the upstream Kubernetes Service.
                                  It defaults to https when Kubernetes Service port is 443, http otherwise.
                                  EOT
                                  "type" = "string"
                                }
                                "serversTransport" = {
                                  "description" = <<-EOT
                                  ServersTransport defines the name of ServersTransport resource to use.
                                  It allows to configure the transport between Traefik and your servers.
                                  Can only be used on a Kubernetes Service.
                                  EOT
                                  "type" = "string"
                                }
                                "sticky" = {
                                  "description" = <<-EOT
                                  Sticky defines the sticky sessions configuration.
                                  More info: https://doc.traefik.io/traefik/v3.1/routing/services/#sticky-sessions
                                  EOT
                                  "properties" = {
                                    "cookie" = {
                                      "description" = "Cookie defines the sticky cookie configuration."
                                      "properties" = {
                                        "httpOnly" = {
                                          "description" = "HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript."
                                          "type" = "boolean"
                                        }
                                        "maxAge" = {
                                          "description" = <<-EOT
                                          MaxAge indicates the number of seconds until the cookie expires.
                                          When set to a negative number, the cookie expires immediately.
                                          When set to zero, the cookie never expires.
                                          EOT
                                          "type" = "integer"
                                        }
                                        "name" = {
                                          "description" = "Name defines the Cookie name."
                                          "type" = "string"
                                        }
                                        "sameSite" = {
                                          "description" = <<-EOT
                                          SameSite defines the same site policy.
                                          More info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite
                                          EOT
                                          "type" = "string"
                                        }
                                        "secure" = {
                                          "description" = "Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS)."
                                          "type" = "boolean"
                                        }
                                      }
                                      "type" = "object"
                                    }
                                  }
                                  "type" = "object"
                                }
                                "strategy" = {
                                  "description" = <<-EOT
                                  Strategy defines the load balancing strategy between the servers.
                                  RoundRobin is the only supported value at the moment.
                                  EOT
                                  "type" = "string"
                                }
                                "weight" = {
                                  "description" = <<-EOT
                                  Weight defines the weight and should only be specified when Name references a TraefikService object
                                  (and to be precise, one that embeds a Weighted Round Robin).
                                  EOT
                                  "type" = "integer"
                                }
                              }
                              "required" = [
                                "name",
                              ]
                              "type" = "object"
                            }
                            "type" = "array"
                          }
                          "syntax" = {
                            "description" = <<-EOT
                            Syntax defines the router's rule syntax.
                            More info: https://doc.traefik.io/traefik/v3.1/routing/routers/#rulesyntax
                            EOT
                            "type" = "string"
                          }
                        }
                        "required" = [
                          "kind",
                          "match",
                        ]
                        "type" = "object"
                      }
                      "type" = "array"
                    }
                    "tls" = {
                      "description" = <<-EOT
                      TLS defines the TLS configuration.
                      More info: https://doc.traefik.io/traefik/v3.1/routing/routers/#tls
                      EOT
                      "properties" = {
                        "certResolver" = {
                          "description" = <<-EOT
                          CertResolver defines the name of the certificate resolver to use.
                          Cert resolvers have to be configured in the static configuration.
                          More info: https://doc.traefik.io/traefik/v3.1/https/acme/#certificate-resolvers
                          EOT
                          "type" = "string"
                        }
                        "domains" = {
                          "description" = <<-EOT
                          Domains defines the list of domains that will be used to issue certificates.
                          More info: https://doc.traefik.io/traefik/v3.1/routing/routers/#domains
                          EOT
                          "items" = {
                            "description" = "Domain holds a domain name with SANs."
                            "properties" = {
                              "main" = {
                                "description" = "Main defines the main domain name."
                                "type" = "string"
                              }
                              "sans" = {
                                "description" = "SANs defines the subject alternative domain names."
                                "items" = {
                                  "type" = "string"
                                }
                                "type" = "array"
                              }
                            }
                            "type" = "object"
                          }
                          "type" = "array"
                        }
                        "options" = {
                          "description" = <<-EOT
                          Options defines the reference to a TLSOption, that specifies the parameters of the TLS connection.
                          If not defined, the `default` TLSOption is used.
                          More info: https://doc.traefik.io/traefik/v3.1/https/tls/#tls-options
                          EOT
                          "properties" = {
                            "name" = {
                              "description" = <<-EOT
                              Name defines the name of the referenced TLSOption.
                              More info: https://doc.traefik.io/traefik/v3.1/routing/providers/kubernetes-crd/#kind-tlsoption
                              EOT
                              "type" = "string"
                            }
                            "namespace" = {
                              "description" = <<-EOT
                              Namespace defines the namespace of the referenced TLSOption.
                              More info: https://doc.traefik.io/traefik/v3.1/routing/providers/kubernetes-crd/#kind-tlsoption
                              EOT
                              "type" = "string"
                            }
                          }
                          "required" = [
                            "name",
                          ]
                          "type" = "object"
                        }
                        "secretName" = {
                          "description" = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details."
                          "type" = "string"
                        }
                        "store" = {
                          "description" = <<-EOT
                          Store defines the reference to the TLSStore, that will be used to store certificates.
                          Please note that only `default` TLSStore can be used.
                          EOT
                          "properties" = {
                            "name" = {
                              "description" = <<-EOT
                              Name defines the name of the referenced TLSStore.
                              More info: https://doc.traefik.io/traefik/v3.1/routing/providers/kubernetes-crd/#kind-tlsstore
                              EOT
                              "type" = "string"
                            }
                            "namespace" = {
                              "description" = <<-EOT
                              Namespace defines the namespace of the referenced TLSStore.
                              More info: https://doc.traefik.io/traefik/v3.1/routing/providers/kubernetes-crd/#kind-tlsstore
                              EOT
                              "type" = "string"
                            }
                          }
                          "required" = [
                            "name",
                          ]
                          "type" = "object"
                        }
                      }
                      "type" = "object"
                    }
                  }
                  "required" = [
                    "routes",
                  ]
                  "type" = "object"
                }
              }
              "required" = [
                "metadata",
                "spec",
              ]
              "type" = "object"
            }
          }
          "served" = true
          "storage" = true
        },
      ]
    }
  }
}

# Ждем создания CRD
resource "time_sleep" "wait_for_crds" {
  depends_on = [kubernetes_manifest.traefik_ingressroute_crd]
  create_duration = "30s"
}

variable "install_traefik_crds" {
  description = "Whether to install Traefik CRDs. Set to false if Traefik manages its own CRDs."
  type        = bool
  default     = false  # Default to false since Traefik usually manages its own CRDs
} 