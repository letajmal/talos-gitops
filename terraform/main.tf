# argocd
resource "helm_release" "argocd" {
  name       = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace = "argocd"
  create_namespace = true
  version = "7.5.2"
}

# 
resource "helm_release" "sealed-secrets" {
  name       = "sealed-secrets"

  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  namespace = "kube-system"
  version = "2.16.1"

  set {
    name  = "fullnameOverride"
    value = "sealed-secrets-controller"
    type = "string"
  }
}