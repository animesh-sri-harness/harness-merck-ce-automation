# Merck TSA §1: App A Admin / App A Dev → HarnessDelegateRole / ChaosExecutionRole.

locals {
  rbac_resource_group = "_all_project_level_resources"

  harness_delegate_role_permissions = [
    "chaos_chaosexperiment_view",
    "chaos_chaosexperiment_edit",
    "chaos_chaosexperiment_delete",
    "chaos_chaosexperiment_execute",
    "chaos_chaosinfrastructure_view",
    "chaos_chaosinfrastructure_edit",
    "chaos_chaosinfrastructure_delete",
    "chaos_chaoshub_view",
    "chaos_chaoshub_edit",
    "chaos_chaoshub_manage",
    "chaos_chaoshub_access",
    "chaos_chaossecuritygovernance_view",
    "chaos_chaossecuritygovernance_edit",
    "chaos_chaosfault_view",
    "chaos_chaosfault_edit",
    "chaos_chaosprobe_view",
    "chaos_chaosprobe_edit",
    "chaos_environment_executeChaosExperiment",
  ]

  chaos_execution_role_permissions = [
    "chaos_chaosexperiment_view",
    "chaos_chaosexperiment_execute",
    "chaos_chaoshub_access",
    "chaos_chaosfault_view",
    "chaos_environment_executeChaosExperiment",
  ]
}

resource "harness_platform_roles" "harness_delegate_role" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.app_a]

  identifier           = "HarnessDelegateRole"
  name                 = "HarnessDelegateRole"
  org_id               = local.org_id
  project_id           = local.project_id
  description          = "Configure chaos infra, delegates, and governance for ${var.project_name}"
  permissions          = local.harness_delegate_role_permissions
  allowed_scope_levels = ["project"]
  tags                 = local.tags_set
}

resource "harness_platform_roles" "chaos_execution_role" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.app_a]

  identifier           = "ChaosExecutionRole"
  name                 = "ChaosExecutionRole"
  org_id               = local.org_id
  project_id           = local.project_id
  description          = "Run chaos experiments only for ${var.project_name}"
  permissions          = local.chaos_execution_role_permissions
  allowed_scope_levels = ["project"]
  tags                 = local.tags_set
}

resource "harness_platform_usergroup" "app_a_admin" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.app_a]

  identifier  = "app_a_admin"
  name        = "App A Admin"
  org_id      = local.org_id
  project_id  = local.project_id
  description = "Administrators for ${var.project_name} chaos configuration"
  user_emails = var.app_a_admin_emails
  tags        = local.tags_set
}

resource "harness_platform_usergroup" "app_a_dev" {
  count = var.create_rbac ? 1 : 0

  depends_on = [harness_platform_project.app_a]

  identifier  = "app_a_dev"
  name        = "App A Dev"
  org_id      = local.org_id
  project_id  = local.project_id
  description = "Developers who run chaos experiments for ${var.project_name}"
  user_emails = var.app_a_dev_emails
  tags        = local.tags_set
}

resource "harness_platform_role_assignments" "app_a_admin" {
  count = var.create_rbac ? 1 : 0

  depends_on = [
    harness_platform_roles.harness_delegate_role[0],
    harness_platform_usergroup.app_a_admin[0],
  ]

  org_id                    = local.org_id
  project_id                = local.project_id
  resource_group_identifier = local.rbac_resource_group

  principal {
    identifier  = harness_platform_usergroup.app_a_admin[0].identifier
    type        = "USER_GROUP"
    scope_level = "project"
  }

  role_reference {
    identifier  = harness_platform_roles.harness_delegate_role[0].identifier
    scope_level = "project"
  }
}

resource "harness_platform_role_assignments" "app_a_dev" {
  count = var.create_rbac ? 1 : 0

  depends_on = [
    harness_platform_roles.chaos_execution_role[0],
    harness_platform_usergroup.app_a_dev[0],
  ]

  org_id                    = local.org_id
  project_id                = local.project_id
  resource_group_identifier = local.rbac_resource_group

  principal {
    identifier  = harness_platform_usergroup.app_a_dev[0].identifier
    type        = "USER_GROUP"
    scope_level = "project"
  }

  role_reference {
    identifier  = harness_platform_roles.chaos_execution_role[0].identifier
    scope_level = "project"
  }
}
