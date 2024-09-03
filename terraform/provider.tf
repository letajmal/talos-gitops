provider "helm" {
  kubernetes {
    config_path = "~/talos/kubeconfig"
  }
}