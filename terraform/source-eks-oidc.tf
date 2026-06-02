# Read OIDC from existing control (source) EKS clusters for IRSA trust policies.
# Kubernetes namespaces/KSAs are created and managed by Merck outside this repo.

data "aws_eks_cluster" "dev" {
  count    = contains(keys(local.oidc_environments), "dev") ? 1 : 0
  provider = aws.source_dev
  name     = local.environments_resolved["dev"].source_eks_cluster_name
}

data "aws_iam_openid_connect_provider" "dev" {
  count    = contains(keys(local.oidc_environments), "dev") ? 1 : 0
  provider = aws.source_dev
  url      = data.aws_eks_cluster.dev[0].identity[0].oidc[0].issuer
}

data "aws_eks_cluster" "uat" {
  count    = contains(keys(local.oidc_environments), "uat") ? 1 : 0
  provider = aws.source_uat
  name     = local.environments_resolved["uat"].source_eks_cluster_name
}

data "aws_iam_openid_connect_provider" "uat" {
  count    = contains(keys(local.oidc_environments), "uat") ? 1 : 0
  provider = aws.source_uat
  url      = data.aws_eks_cluster.uat[0].identity[0].oidc[0].issuer
}

data "aws_eks_cluster" "prod" {
  count    = contains(keys(local.oidc_environments), "prod") ? 1 : 0
  provider = aws.source_prod
  name     = local.environments_resolved["prod"].source_eks_cluster_name
}

data "aws_iam_openid_connect_provider" "prod" {
  count    = contains(keys(local.oidc_environments), "prod") ? 1 : 0
  provider = aws.source_prod
  url      = data.aws_eks_cluster.prod[0].identity[0].oidc[0].issuer
}

locals {
  env_oidc = merge(
    {
      for k, v in local.environments_resolved : k => {
        arn  = ""
        host = ""
      }
    },
    contains(keys(local.oidc_environments), "dev") ? {
      dev = {
        arn  = data.aws_iam_openid_connect_provider.dev[0].arn
        host = replace(data.aws_eks_cluster.dev[0].identity[0].oidc[0].issuer, "https://", "")
      }
    } : {},
    contains(keys(local.oidc_environments), "uat") ? {
      uat = {
        arn  = data.aws_iam_openid_connect_provider.uat[0].arn
        host = replace(data.aws_eks_cluster.uat[0].identity[0].oidc[0].issuer, "https://", "")
      }
    } : {},
    contains(keys(local.oidc_environments), "prod") ? {
      prod = {
        arn  = data.aws_iam_openid_connect_provider.prod[0].arn
        host = replace(data.aws_eks_cluster.prod[0].identity[0].oidc[0].issuer, "https://", "")
      }
    } : {},
  )
}
