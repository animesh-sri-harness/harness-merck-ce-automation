resource "kubernetes_namespace" "chaos_env" {
  for_each = var.environments

  metadata {
    name = each.value.k8s_namespace
    labels = {
      "merck.harness.io/environment" = each.key
      "app.kubernetes.io/managed-by" = "terraform"
      "customer"                     = var.customer_label
    }
  }
}
