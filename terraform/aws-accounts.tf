# Per-environment AWS providers for source (control EKS) and target (chaos execution) accounts.
# Merck installs one control EKS + delegate per environment in the source account;
# ChaosExecutionRole is created in the separate target account for that environment.

locals {
  env_aws_regions = {
    dev  = try(local.environments_resolved["dev"].source_eks_region, var.aws_region)
    uat  = try(local.environments_resolved["uat"].source_eks_region, var.aws_region)
    prod = try(local.environments_resolved["prod"].source_eks_region, var.aws_region)
  }

  source_assume_role_arn = {
    dev  = try(var.aws_deploy_assume_role_arns.source.dev, "")
    uat  = try(var.aws_deploy_assume_role_arns.source.uat, "")
    prod = try(var.aws_deploy_assume_role_arns.source.prod, "")
  }

  target_assume_role_arn = {
    dev  = try(var.aws_deploy_assume_role_arns.target.dev, "")
    uat  = try(var.aws_deploy_assume_role_arns.target.uat, "")
    prod = try(var.aws_deploy_assume_role_arns.target.prod, "")
  }
}

provider "aws" {
  alias  = "source_dev"
  region = local.env_aws_regions.dev

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.source_assume_role_arn.dev != "" ? [local.source_assume_role_arn.dev] : []
    content {
      role_arn = assume_role.value
    }
  }
}

provider "aws" {
  alias  = "source_uat"
  region = local.env_aws_regions.uat

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.source_assume_role_arn.uat != "" ? [local.source_assume_role_arn.uat] : []
    content {
      role_arn = assume_role.value
    }
  }
}

provider "aws" {
  alias  = "source_prod"
  region = local.env_aws_regions.prod

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.source_assume_role_arn.prod != "" ? [local.source_assume_role_arn.prod] : []
    content {
      role_arn = assume_role.value
    }
  }
}

provider "aws" {
  alias  = "target_dev"
  region = local.env_aws_regions.dev

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.target_assume_role_arn.dev != "" ? [local.target_assume_role_arn.dev] : []
    content {
      role_arn = assume_role.value
    }
  }
}

provider "aws" {
  alias  = "target_uat"
  region = local.env_aws_regions.uat

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.target_assume_role_arn.uat != "" ? [local.target_assume_role_arn.uat] : []
    content {
      role_arn = assume_role.value
    }
  }
}

provider "aws" {
  alias  = "target_prod"
  region = local.env_aws_regions.prod

  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null

  dynamic "assume_role" {
    for_each = local.target_assume_role_arn.prod != "" ? [local.target_assume_role_arn.prod] : []
    content {
      role_arn = assume_role.value
    }
  }
}
