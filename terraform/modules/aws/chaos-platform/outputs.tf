output "namespace_names" {
  value = { for k, v in kubernetes_namespace.chaos_env : k => v.metadata[0].name }
}
