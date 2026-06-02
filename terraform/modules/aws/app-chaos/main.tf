locals {
  slug_k8s = replace(var.app_slug, "_", "-")
  ksa_name = "ksa-${local.slug_k8s}-${var.env_key}"

  k8s_rbac_name = var.legacy_resource_naming ? "chaos-executor-${var.env_key}" : "chaos-executor-${local.slug_k8s}-${var.env_key}"

  assume_target_policy_name = var.legacy_resource_naming ? "assume-target-${var.env_key}" : "assume-target-${var.iam_role_suffix}"
}

resource "aws_iam_role" "harness_control" {
  count = var.create_aws_iam && var.env.enable_chaos ? 1 : 0

  name = "${var.platform.harness_delegate_iam_role_name}-${var.iam_role_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = var.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_issuer_host}:aud" = "sts.amazonaws.com"
          "${var.oidc_issuer_host}:sub" = "system:serviceaccount:${var.env.k8s_namespace}:${local.ksa_name}"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Application = var.app_slug
    Environment = var.env_key
  })
}

resource "aws_iam_role" "harness_target" {
  count = var.create_aws_iam ? 1 : 0

  name = "${var.platform.chaos_execution_iam_role_name}-${var.iam_role_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.create_aws_iam && var.env.enable_chaos ? aws_iam_role.harness_control[0].arn : "arn:aws:iam::${var.control_account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Application = var.app_slug
    Environment = var.env_key
  })
}

resource "aws_iam_role_policy" "harness_control_assume_target" {
  count = var.create_aws_iam && var.env.enable_chaos ? 1 : 0

  name = local.assume_target_policy_name
  role = aws_iam_role.harness_control[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.harness_target[0].arn
    }]
  })
}

resource "aws_iam_role_policy" "harness_target_chaos" {
  count = var.create_aws_iam ? 1 : 0

  name = "chaos-tag-gated-faults"
  role = aws_iam_role.harness_target[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DiscoverResources"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances", "ec2:DescribeInstanceStatus",
          "ssm:DescribeInstanceInformation", "ssm:ListCommandInvocations",
          "rds:DescribeDBInstances", "lambda:ListFunctions", "lambda:GetFunction",
        ]
        Resource = "*"
      },
      {
        Sid      = "TagGatedEC2Faults"
        Effect   = "Allow"
        Action   = ["ec2:StopInstances", "ec2:RebootInstances"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.platform.chaos_allowed_tag_key}" = var.platform.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid      = "TagGatedSSMFaults"
        Effect   = "Allow"
        Action   = ["ssm:SendCommand", "ssm:GetCommandInvocation"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/${var.platform.chaos_allowed_tag_key}" = var.platform.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid      = "TagGatedRDSFaults"
        Effect   = "Allow"
        Action   = ["rds:RebootDBInstance", "rds:StopDBInstance"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.platform.chaos_allowed_tag_key}" = var.platform.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid      = "TagGatedLambdaFaults"
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction", "lambda:UpdateFunctionConfiguration"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.platform.chaos_allowed_tag_key}" = var.platform.chaos_allowed_tag_value
          }
        }
      },
    ]
  })
}

resource "kubernetes_service_account" "chaos_executor" {
  count = var.env.enable_chaos ? 1 : 0

  metadata {
    name      = local.ksa_name
    namespace = var.env.k8s_namespace
    annotations = var.create_aws_iam && var.env.enable_chaos ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.harness_control[0].arn
    } : {}
    labels = {
      "merck.harness.io/app"         = var.app_slug
      "merck.harness.io/environment" = var.env_key
    }
  }
}

resource "kubernetes_role" "chaos_executor" {
  count = var.env.enable_chaos ? 1 : 0

  metadata {
    name      = local.k8s_rbac_name
    namespace = var.env.k8s_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "events"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch", "deletecollection"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "chaos_executor" {
  count = var.env.enable_chaos ? 1 : 0

  metadata {
    name      = local.k8s_rbac_name
    namespace = var.env.k8s_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.chaos_executor[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.chaos_executor[0].metadata[0].name
    namespace = var.env.k8s_namespace
  }
}
