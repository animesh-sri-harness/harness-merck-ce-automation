module "harness_org" {
  source = "./modules/harness/org"

  harness_account_id     = var.harness_account_id
  org                    = var.org
  tags_set               = local.tags_set
  environments           = local.environments_resolved
  create_org             = var.create_harness_org
  existing_org_id        = var.harness_org_id
  create_delegate_tokens = var.create_delegate_tokens
}

module "aws_app_chaos_dev" {
  for_each = { for k, v in local.app_env_matrix : k => v if v.env_key == "dev" }

  source = "./modules/aws/app-chaos"

  app_key  = each.value.app_key
  app_slug = each.value.app.slug
  env_key  = each.value.env_key
  env      = each.value.env
  platform = var.platform
  tags     = local.tags

  create_aws_iam         = var.create_aws_iam
  source_account_id      = each.value.env.source_account_id
  target_account_id      = each.value.env.target_account_id
  oidc_provider_arn      = local.env_oidc["dev"].arn
  oidc_issuer_host       = local.env_oidc["dev"].host
  iam_role_suffix        = each.value.iam_role_suffix
  legacy_resource_naming = local.single_application

  providers = {
    aws.source = aws.source_dev
    aws.target = aws.target_dev
  }
}

module "aws_app_chaos_uat" {
  for_each = { for k, v in local.app_env_matrix : k => v if v.env_key == "uat" }

  source = "./modules/aws/app-chaos"

  app_key  = each.value.app_key
  app_slug = each.value.app.slug
  env_key  = each.value.env_key
  env      = each.value.env
  platform = var.platform
  tags     = local.tags

  create_aws_iam         = var.create_aws_iam
  source_account_id      = each.value.env.source_account_id
  target_account_id      = each.value.env.target_account_id
  oidc_provider_arn      = local.env_oidc["uat"].arn
  oidc_issuer_host       = local.env_oidc["uat"].host
  iam_role_suffix        = each.value.iam_role_suffix
  legacy_resource_naming = local.single_application

  providers = {
    aws.source = aws.source_uat
    aws.target = aws.target_uat
  }
}

module "aws_app_chaos_prod" {
  for_each = { for k, v in local.app_env_matrix : k => v if v.env_key == "prod" }

  source = "./modules/aws/app-chaos"

  app_key  = each.value.app_key
  app_slug = each.value.app.slug
  env_key  = each.value.env_key
  env      = each.value.env
  platform = var.platform
  tags     = local.tags

  create_aws_iam         = var.create_aws_iam
  source_account_id      = each.value.env.source_account_id
  target_account_id      = each.value.env.target_account_id
  oidc_provider_arn      = local.env_oidc["prod"].arn
  oidc_issuer_host       = local.env_oidc["prod"].host
  iam_role_suffix        = each.value.iam_role_suffix
  legacy_resource_naming = local.single_application

  providers = {
    aws.source = aws.source_prod
    aws.target = aws.target_prod
  }
}

module "harness_application" {
  for_each = local.applications_enabled

  source = "./modules/harness/application"

  org_id       = local.harness_org_id
  app_key      = each.key
  app          = each.value
  environments = local.environments_resolved
  tags_set     = local.tags_set
  platform     = var.platform
  aws_region   = var.aws_region

  create_rbac                    = var.create_rbac && try(each.value.create_rbac, true)
  create_chaos_guard             = var.create_chaos_guard
  chaos_guard_destructive_faults = var.chaos_guard_destructive_faults

  execution_role_arns = {
    for pair_key, pair in local.app_env_matrix :
    pair.env_key => coalesce(
      try(module.aws_app_chaos_dev[pair_key].target_role_arn, null),
      try(module.aws_app_chaos_uat[pair_key].target_role_arn, null),
      try(module.aws_app_chaos_prod[pair_key].target_role_arn, null),
    )
    if pair.app_key == each.key && coalesce(
      try(module.aws_app_chaos_dev[pair_key].target_role_arn, null),
      try(module.aws_app_chaos_uat[pair_key].target_role_arn, null),
      try(module.aws_app_chaos_prod[pair_key].target_role_arn, null),
    ) != null
  }

  depends_on = [
    module.aws_app_chaos_dev,
    module.aws_app_chaos_uat,
    module.aws_app_chaos_prod,
  ]
}
