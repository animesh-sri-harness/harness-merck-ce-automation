module "harness_org" {
  source = "./modules/harness/org"

  harness_account_id = var.harness_account_id
  org                = var.org
  tags_set           = local.tags_set
  environments       = local.environments_resolved
}

module "control_plane" {
  source = "./modules/aws/control-plane"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region
  tags        = local.tags

  eks_cluster_name       = var.eks_cluster_name
  eks_cluster_version    = var.eks_cluster_version
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_desired_size  = var.eks_node_desired_size
  eks_node_min_size      = var.eks_node_min_size
  eks_node_max_size      = var.eks_node_max_size

  environments              = local.environments_resolved
  install_delegates         = var.install_delegates
  harness_account_id        = var.harness_account_id
  harness_manager_endpoint  = var.harness_manager_endpoint
  delegate_image            = var.delegate_image
  delegate_namespace_prefix = var.delegate_namespace_prefix
  delegate_tokens           = module.harness_org.delegate_tokens
  chaos_control_namespace   = var.platform.chaos_control_namespace
  eks_cluster_iam_role_name = var.platform.eks_cluster_iam_role_name
  eks_node_iam_role_name    = var.platform.eks_node_iam_role_name
}

module "aws_chaos_platform" {
  source = "./modules/aws/chaos-platform"

  environments   = local.environments_resolved
  customer_label = lookup(local.tags, "customer", var.org.prefix)
}

module "aws_app_chaos" {
  for_each = local.app_env_matrix

  source = "./modules/aws/app-chaos"

  app_key  = each.value.app_key
  app_slug = each.value.app.slug
  env_key  = each.value.env_key
  env      = each.value.env
  platform = var.platform
  tags     = local.tags

  create_aws_iam         = var.create_aws_iam
  control_account_id     = local.control_account_id
  oidc_provider_arn      = module.control_plane.oidc_provider_arn
  oidc_issuer_host       = replace(module.control_plane.cluster_oidc_issuer_url, "https://", "")
  iam_role_suffix        = each.value.iam_role_suffix
  legacy_resource_naming = local.single_application
}

module "harness_application" {
  for_each = local.applications_enabled

  source = "./modules/harness/application"

  org_id       = module.harness_org.org_id
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
    pair.env_key => module.aws_app_chaos[pair_key].target_role_arn
    if pair.app_key == each.key && module.aws_app_chaos[pair_key].target_role_arn != null
  }

  depends_on = [module.aws_app_chaos]
}

module "aws_demo_workload" {
  for_each = {
    for k, app in local.applications_enabled : k => app
    if try(app.create_demo_ec2, false)
  }

  source = "./modules/aws/demo-workload"

  name_prefix            = local.name_prefix
  vpc_id                 = module.control_plane.vpc_id
  subnet_id              = module.control_plane.public_subnet_ids[0]
  app_slug               = each.value.slug
  env_key                = each.value.demo_ec2_env
  instance_name          = coalesce(try(each.value.demo_ec2_name, null), "${local.name_prefix}-demo-${each.value.slug}")
  instance_type          = coalesce(try(each.value.demo_ec2_type, null), "t3.micro")
  platform               = var.platform
  tags                   = local.tags
  legacy_resource_naming = local.single_application
}
