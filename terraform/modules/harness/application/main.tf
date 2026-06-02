locals {
  slug_k8s = replace(var.app.slug, "_", "-")

  admin_group_id = "${var.app.slug}_admin"
  dev_group_id   = "${var.app.slug}_dev"

  rbac_resource_group = var.platform.rbac_resource_group

  harness_delegate_role_permissions = [
    "chaos_chaosexperiment_view", "chaos_chaosexperiment_edit", "chaos_chaosexperiment_delete",
    "chaos_chaosexperiment_execute", "chaos_chaosinfrastructure_view", "chaos_chaosinfrastructure_edit",
    "chaos_chaosinfrastructure_delete", "chaos_chaoshub_view", "chaos_chaoshub_edit", "chaos_chaoshub_manage",
    "chaos_chaoshub_access", "chaos_chaossecuritygovernance_view", "chaos_chaossecuritygovernance_edit",
    "chaos_chaosfault_view", "chaos_chaosfault_edit", "chaos_chaosprobe_view", "chaos_chaosprobe_edit",
    "chaos_environment_executeChaosExperiment",
  ]

  chaos_execution_role_permissions = [
    "chaos_chaosexperiment_view", "chaos_chaosexperiment_execute", "chaos_chaoshub_access",
    "chaos_chaosfault_view", "chaos_environment_executeChaosExperiment",
  ]

  chaos_guard_blocked_envs = [
    for k, v in var.environments : k if try(v.chaos_guard_block, false)
  ]

  chaos_hub_id   = coalesce(try(var.app.chaos_hub_id, null), "${var.app.slug}_chaos_hub")
  chaos_hub_name = coalesce(try(var.app.chaos_hub_name, null), "${var.app.name} Chaos Hub")
}

resource "harness_platform_project" "this" {
  identifier  = var.app.slug
  name        = var.app.name
  org_id      = var.org_id
  description = coalesce(var.app.description, "Chaos infrastructure for ${var.app.name}")
  tags        = var.tags_set
}

resource "harness_platform_roles" "harness_delegate_role" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.this]

  identifier           = "HarnessDelegateRole"
  name                 = "HarnessDelegateRole"
  org_id               = var.org_id
  project_id           = var.app.slug
  description          = "Configure chaos for ${var.app.name}"
  permissions          = local.harness_delegate_role_permissions
  allowed_scope_levels = ["project"]
  tags                 = var.tags_set
}

resource "harness_platform_roles" "chaos_execution_role" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.this]

  identifier           = "ChaosExecutionRole"
  name                 = "ChaosExecutionRole"
  org_id               = var.org_id
  project_id           = var.app.slug
  description          = "Execute chaos experiments for ${var.app.name}"
  permissions          = local.chaos_execution_role_permissions
  allowed_scope_levels = ["project"]
  tags                 = var.tags_set
}

resource "harness_platform_usergroup" "admin" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.this]

  identifier  = local.admin_group_id
  name        = coalesce(var.app.admin_group_name, "${var.app.name} Admin")
  org_id      = var.org_id
  project_id  = var.app.slug
  description = "Administrators for ${var.app.name}"
  user_emails = var.app.admin_emails
  tags        = var.tags_set
}

resource "harness_platform_usergroup" "dev" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.this]

  identifier  = local.dev_group_id
  name        = coalesce(var.app.dev_group_name, "${var.app.name} Dev")
  org_id      = var.org_id
  project_id  = var.app.slug
  description = "Developers for ${var.app.name}"
  user_emails = var.app.dev_emails
  tags        = var.tags_set
}

resource "harness_platform_role_assignments" "admin" {
  count = var.create_rbac ? 1 : 0

  org_id                    = var.org_id
  project_id                = var.app.slug
  resource_group_identifier = local.rbac_resource_group

  principal {
    identifier  = harness_platform_usergroup.admin[0].identifier
    type        = "USER_GROUP"
    scope_level = "project"
  }

  role_reference {
    identifier  = harness_platform_roles.harness_delegate_role[0].identifier
    scope_level = "project"
  }
}

resource "harness_platform_role_assignments" "dev" {
  count = var.create_rbac ? 1 : 0

  org_id                    = var.org_id
  project_id                = var.app.slug
  resource_group_identifier = local.rbac_resource_group

  principal {
    identifier  = harness_platform_usergroup.dev[0].identifier
    type        = "USER_GROUP"
    scope_level = "project"
  }

  role_reference {
    identifier  = harness_platform_roles.chaos_execution_role[0].identifier
    scope_level = "project"
  }
}

resource "harness_platform_environment" "env" {
  for_each = var.environments

  depends_on = [harness_platform_project.this]

  identifier  = each.value.env_identifier
  name        = upper(each.key)
  org_id      = var.org_id
  project_id  = var.app.slug
  type        = each.value.harness_type
  description = "${var.app.name} – ${each.key}"
  tags        = var.tags_set
}

resource "harness_platform_connector_kubernetes" "env" {
  for_each = var.environments

  depends_on = [harness_platform_project.this]

  identifier  = "k8s_${each.key}"
  name        = "K8s-Control-Cluster-${upper(each.key)}"
  org_id      = var.org_id
  project_id  = var.app.slug
  description = "Control EKS – ${each.value.delegate_name}"

  inherit_from_delegate {
    delegate_selectors = each.value.delegate_tags
  }

  tags = var.tags_set
}

resource "harness_platform_connector_aws" "env" {
  for_each = { for k, v in var.environments : k => v if v.enable_chaos }

  depends_on = [harness_platform_project.this]

  identifier  = "aws_${each.key}"
  name        = "AWS-${upper(each.key)}-Cross-Account"
  org_id      = var.org_id
  project_id  = var.app.slug
  description = "Assume ${var.platform.chaos_execution_iam_role_name} in ${each.value.target_account_id}"

  inherit_from_delegate {
    delegate_selectors = each.value.delegate_tags
    region             = var.aws_region
  }

  cross_account_access {
    role_arn = var.execution_role_arns[each.key]
  }

  tags = var.tags_set
}

resource "harness_platform_infrastructure" "env" {
  for_each = var.environments

  depends_on = [
    harness_platform_environment.env,
    harness_platform_connector_kubernetes.env,
  ]

  identifier      = each.value.infra_identifier
  name            = "Infrastructure-${upper(each.key)}"
  org_id          = var.org_id
  project_id      = var.app.slug
  env_id          = harness_platform_environment.env[each.key].id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"

  yaml = <<-EOT
    infrastructureDefinition:
      name: Infrastructure-${upper(each.key)}
      identifier: ${each.value.infra_identifier}
      orgIdentifier: ${var.org_id}
      projectIdentifier: ${var.app.slug}
      environmentRef: ${harness_platform_environment.env[each.key].id}
      deploymentType: Kubernetes
      type: KubernetesDirect
      allowSimultaneousDeployments: false
      spec:
        connectorRef: ${harness_platform_connector_kubernetes.env[each.key].identifier}
        namespace: ${each.value.k8s_namespace}
        releaseName: ${var.app.slug}-${each.key}-<+INFRA_KEY>
  EOT

  tags = var.tags_set
}

resource "harness_chaos_infrastructure_v2" "env" {
  for_each = { for k, v in var.environments : k => v if v.enable_chaos }

  depends_on = [harness_platform_infrastructure.env]

  org_id         = var.org_id
  project_id     = var.app.slug
  environment_id = harness_platform_environment.env[each.key].id
  infra_id       = harness_platform_infrastructure.env[each.key].id
  name           = "chaos-infra-${each.key}"
  description    = "${var.app.name} chaos – ${each.key}"

  namespace       = each.value.k8s_namespace
  infra_type      = "KUBERNETESV2"
  service_account = "ksa-${local.slug_k8s}-${each.key}"

  tags = var.tags_set
}

resource "harness_chaos_hub_v2" "project" {
  depends_on = [harness_platform_project.this]

  org_id      = var.org_id
  project_id  = var.app.slug
  identity    = local.chaos_hub_id
  name        = local.chaos_hub_name
  description = "Chaos hub for ${var.app.name}"
  tags        = [var.app_key, "chaos-hub"]
}

resource "harness_chaos_security_governance_condition" "block_destructive" {
  for_each = var.create_chaos_guard ? toset(local.chaos_guard_blocked_envs) : toset([])

  depends_on = [
    harness_platform_infrastructure.env,
    harness_chaos_infrastructure_v2.env,
  ]

  name        = "${var.app.slug}-block-${each.key}-destructive"
  description = "${var.app.name}: block destructive faults on ${upper(each.key)}"
  org_id      = var.org_id
  project_id  = var.app.slug
  infra_type  = "KubernetesV2"

  k8s_spec {
    infra_spec {
      operator  = "EQUAL_TO"
      infra_ids = ["${harness_platform_environment.env[each.key].id}/${harness_chaos_infrastructure_v2.env[each.key].id}"]
    }
  }

  dynamic "fault_spec" {
    for_each = [1]
    content {
      operator = "EQUAL_TO"
      dynamic "faults" {
        for_each = var.chaos_guard_destructive_faults
        content {
          fault_type = "FAULT"
          name       = faults.value
        }
      }
    }
  }

  tags = [var.app.slug, "chaosguard", "env:${each.key}"]
}

resource "harness_chaos_security_governance_rule" "block_destructive" {
  count = var.create_chaos_guard && length(local.chaos_guard_blocked_envs) > 0 ? 1 : 0

  depends_on = [harness_chaos_security_governance_condition.block_destructive]

  name        = "${var.app.slug}-block-destructive-chaos"
  description = "${var.app.name}: block destructive chaos in guarded environments"
  org_id      = var.org_id
  project_id  = var.app.slug
  is_enabled  = true
  condition_ids = [
    for env in local.chaos_guard_blocked_envs :
    harness_chaos_security_governance_condition.block_destructive[env].id
  ]
  user_group_ids = []

  time_windows {
    time_zone  = "UTC"
    start_time = 0
    duration   = "24h"
  }

  tags = concat(var.tags_set, ["chaosguard=block"])
}
