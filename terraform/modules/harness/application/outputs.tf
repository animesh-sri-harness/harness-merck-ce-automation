output "project_id" {
  value = harness_platform_project.this.id
}

output "project_slug" {
  value = var.app.slug
}

output "environment_ids" {
  value = { for k, v in harness_platform_environment.env : k => v.id }
}

output "infrastructure_ids" {
  value = { for k, v in harness_platform_infrastructure.env : k => v.id }
}

output "chaos_infrastructure_ids" {
  value = { for k, v in harness_chaos_infrastructure_v2.env : k => v.id }
}

output "rbac" {
  value = var.create_rbac ? {
    admin_group    = harness_platform_usergroup.admin[0].identifier
    dev_group      = harness_platform_usergroup.dev[0].identifier
    delegate_role  = harness_platform_roles.harness_delegate_role[0].identifier
    execution_role = harness_platform_roles.chaos_execution_role[0].identifier
  } : null
}
