resource "kubernetes_namespace" "chaos_control" {
  depends_on = [module.eks]

  metadata {
    name = var.chaos_control_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "customer"                     = "merck"
    }
  }
}

resource "kubernetes_namespace" "chaos_env" {
  for_each = local.environments

  depends_on = [module.eks]

  metadata {
    name = each.value.k8s_namespace
    labels = {
      "merck.harness.io/environment" = each.key
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# KSAs in per-env namespaces (Merck: KSA-Dev App A, KSA-UAT App A) with IRSA → control role.
resource "kubernetes_service_account" "chaos_executor" {
  for_each = { for k, v in local.environments : k => v if v.enable_chaos }

  metadata {
    name      = "ksa-${local.application_slug_k8s}-${each.key}"
    namespace = each.value.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.harness_control[each.key].arn
    }
    labels = {
      "merck.harness.io/app"         = var.application_slug
      "merck.harness.io/environment" = each.key
    }
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.chaos_env,
    aws_iam_role.harness_control,
  ]
}

# K8s RBAC for transient chaos pods (pod-delete and discovery in env namespace).
resource "kubernetes_role" "chaos_executor" {
  for_each = { for k, v in local.environments : k => v if v.enable_chaos }

  metadata {
    name      = "chaos-executor-${each.key}"
    namespace = each.value.k8s_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "events"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch", "deletecollection"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [kubernetes_namespace.chaos_env]
}

resource "kubernetes_role_binding" "chaos_executor" {
  for_each = { for k, v in local.environments : k => v if v.enable_chaos }

  metadata {
    name      = "chaos-executor-${each.key}"
    namespace = each.value.k8s_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.chaos_executor[each.key].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.chaos_executor[each.key].metadata[0].name
    namespace = each.value.k8s_namespace
  }

  depends_on = [
    kubernetes_role.chaos_executor,
    kubernetes_service_account.chaos_executor,
  ]
}
