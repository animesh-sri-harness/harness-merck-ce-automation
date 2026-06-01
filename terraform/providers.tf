provider "harness" {
  endpoint         = var.harness_endpoint
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
  # Static keys only when no SSO profile is configured.
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null
}

locals {
  aws_cli_profile_args = var.aws_profile != "" ? ["--profile", var.aws_profile] : []

  eks_exec_env = merge(
    { AWS_REGION = var.aws_region },
    var.aws_profile != "" ? { AWS_PROFILE = var.aws_profile } : {},
    var.aws_profile == "" && var.aws_access_key_id != null ? {
      AWS_ACCESS_KEY_ID     = var.aws_access_key_id
      AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
      AWS_SESSION_TOKEN     = coalesce(var.aws_session_token, "")
    } : {},
  )

  eks_get_token_args = concat(
    ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region],
    local.aws_cli_profile_args,
  )
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.eks_get_token_args
    env         = local.eks_exec_env
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.eks_get_token_args
      env         = local.eks_exec_env
    }
  }
}
