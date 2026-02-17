// Examples of deploying kubernetes resources directly.
// You may use other deployment methods as needed, e.g. ArgoCD.

provider "kubernetes" {
  host = google_container_cluster.velda_k8s_cluster.endpoint

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.velda_k8s_cluster.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

resource "kubernetes_config_map" "velda_config_configmap" {
  metadata {
    name = "velda-config"
  }

  data = {
    "velda.yaml" = yamlencode({
      broker = {
        address = "${module.controller.controller_ip}:50051"
      }
    })
  }
}

resource "kubernetes_manifest" "crd" {
  manifest = yamldecode(file("velda.io_agentpools.yaml"))
}

resource "kubernetes_manifest" "agent_pool" {
  manifest = yamldecode(file("agent-shell.yaml"))
}