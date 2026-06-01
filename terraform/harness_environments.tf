resource "harness_platform_environment" "env" {
  for_each = local.environments

  depends_on = [harness_platform_project.app_a]

  identifier  = each.value.env_identifier
  name        = upper(each.key)
  org_id      = local.org_id
  project_id  = local.project_id
  type        = each.value.harness_type
  description = "Merck ${var.project_name} – ${each.key} environment"
  tags        = local.tags_set
}

resource "harness_platform_connector_kubernetes" "env" {
  for_each = local.environments

  depends_on = [harness_platform_project.app_a]

  identifier  = "k8s_${each.key}"
  name        = "K8s-Control-Cluster-${upper(each.key)}"
  org_id      = local.org_id
  project_id  = local.project_id
  description = "Control EKS – delegate ${each.value.delegate_name}"

  inherit_from_delegate {
    delegate_selectors = each.value.delegate_tags
  }

  tags = local.tags_set
}

resource "harness_platform_infrastructure" "env" {
  for_each = local.environments

  depends_on = [
    harness_platform_environment.env,
    harness_platform_connector_kubernetes.env,
  ]

  identifier      = each.value.infra_identifier
  name            = "Infrastructure-${upper(each.key)}"
  org_id          = local.org_id
  project_id      = local.project_id
  env_id          = harness_platform_environment.env[each.key].id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"

  yaml = <<-EOT
    infrastructureDefinition:
      name: Infrastructure-${upper(each.key)}
      identifier: ${each.value.infra_identifier}
      orgIdentifier: ${local.org_id}
      projectIdentifier: ${local.project_id}
      environmentRef: ${harness_platform_environment.env[each.key].id}
      deploymentType: Kubernetes
      type: KubernetesDirect
      allowSimultaneousDeployments: false
      spec:
        connectorRef: ${harness_platform_connector_kubernetes.env[each.key].identifier}
        namespace: ${each.value.k8s_namespace}
        releaseName: merck-${each.key}-<+INFRA_KEY>
  EOT

  tags = local.tags_set
}
