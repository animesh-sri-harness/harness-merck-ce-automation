resource "harness_chaos_infrastructure_v2" "env" {
  for_each = { for k, v in local.environments : k => v if v.enable_chaos }

  depends_on = [harness_platform_infrastructure.env]

  org_id         = local.org_id
  project_id     = local.project_id
  environment_id = harness_platform_environment.env[each.key].id
  infra_id       = harness_platform_infrastructure.env[each.key].id
  name           = "chaos-infra-${each.key}"
  description    = "Delegate-driven chaos infrastructure – ${each.key}"

  namespace       = each.value.k8s_namespace
  infra_type      = "KUBERNETESV2"
  service_account = "ksa-${local.application_slug_k8s}-${each.key}"

  tags = local.tags_set
}

resource "harness_chaos_hub_v2" "project" {
  depends_on = [harness_platform_project.app_a]

  org_id      = local.org_id
  project_id  = local.project_id
  identity    = "merck_chaos_hub"
  name        = "Merck Chaos Hub"
  description = "Project-level chaos hub for ${var.project_name}"
  tags        = ["merck", "chaos-hub"]
}
