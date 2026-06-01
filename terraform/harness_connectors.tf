# AWS connectors – delegate executes; assumes ChaosExecutionRole per env for fault injection.
resource "harness_platform_connector_aws" "env" {
  for_each = { for k, v in local.environments : k => v if v.enable_chaos }

  depends_on = [
    harness_platform_project.app_a,
    aws_iam_role.harness_target,
  ]

  identifier  = "aws_${each.key}"
  name        = "AWS-${upper(each.key)}-Cross-Account"
  org_id      = local.org_id
  project_id  = local.project_id
  description = "Assume ${var.chaos_execution_iam_role_name}-${each.key} in account ${var.target_account_ids[each.key]}"

  inherit_from_delegate {
    delegate_selectors = each.value.delegate_tags
    region             = var.aws_region
  }

  cross_account_access {
    role_arn = aws_iam_role.harness_target[each.key].arn
  }

  tags = local.tags_set
}
