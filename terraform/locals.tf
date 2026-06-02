data "aws_caller_identity" "current" {}

locals {
  org_id   = var.org.identifier
  tags     = var.default_tags
  tags_set = [for k, v in local.tags : "${k}=${v}"]
  name_prefix = coalesce(
    var.platform.aws_resource_prefix != "" ? var.platform.aws_resource_prefix : null,
    "${var.org.prefix}-chaos",
  )

  control_account_id = var.control_account_id != "" ? var.control_account_id : data.aws_caller_identity.current.account_id

  single_application = length(local.applications_enabled) == 1

  applications_enabled = {
    for k, v in var.applications : k => v if try(v.enabled, true)
  }

  environments_resolved = {
    for env_key, env in var.environments : env_key => merge(env, {
      delegate_name     = env.delegate_name != "" ? env.delegate_name : "${var.org.prefix}-delegate-${env_key}"
      delegate_tags     = length(env.delegate_tags) > 0 ? env.delegate_tags : ["${var.org.prefix}-delegate-${env_key}", "env:${env_key}"]
      env_identifier    = env.env_identifier != "" ? env.env_identifier : "env_${env_key}"
      infra_identifier  = env.infra_identifier != "" ? env.infra_identifier : "infra_${env_key}"
      k8s_namespace     = env.k8s_namespace != "" ? env.k8s_namespace : "${var.platform.chaos_namespace_prefix}-${env_key}"
      target_account_id = env.target_account_id != "" ? env.target_account_id : local.control_account_id
    })
  }

  app_env_matrix = merge([
    for app_key, app in local.applications_enabled : {
      for env_key, env in local.environments_resolved :
      "${app_key}/${env_key}" => {
        key             = "${app_key}/${env_key}"
        app_key         = app_key
        env_key         = env_key
        app             = app
        env             = env
        iam_role_suffix = local.single_application ? env_key : "${app.slug}-${env_key}"
      }
    }
  ]...)
}
