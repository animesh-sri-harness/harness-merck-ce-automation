locals {
  slug_k8s = replace(var.app_slug, "_", "-")
  ksa_name = "ksa-${local.slug_k8s}-${var.env_key}"

  k8s_rbac_name = var.legacy_resource_naming ? "chaos-executor-${var.env_key}" : "chaos-executor-${local.slug_k8s}-${var.env_key}"

  assume_target_policy_name = var.legacy_resource_naming ? "assume-target-${var.env_key}" : "assume-target-${var.iam_role_suffix}"

  delegate_role_name  = "${var.platform.harness_delegate_iam_role_name}-${var.iam_role_suffix}"
  execution_role_name = "${var.platform.chaos_execution_iam_role_name}-${var.iam_role_suffix}"

  # Predictable ARNs avoid circular dependencies between source and target accounts.
  delegate_role_arn  = "arn:aws:iam::${var.source_account_id}:role/${local.delegate_role_name}"
  execution_role_arn = "arn:aws:iam::${var.target_account_id}:role/${local.execution_role_name}"
}

# Source account (control EKS): IRSA role for chaos pods running on the env delegate cluster.
resource "aws_iam_role" "harness_control" {
  provider = aws.source
  count    = var.create_aws_iam && var.env.enable_chaos ? 1 : 0

  name = local.delegate_role_name

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
    AccountRole = "source-control"
  })
}

resource "aws_iam_role_policy" "harness_control_assume_target" {
  provider = aws.source
  count    = var.create_aws_iam && var.env.enable_chaos ? 1 : 0

  name = local.assume_target_policy_name
  role = aws_iam_role.harness_control[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = local.execution_role_arn
    }]
  })
}

# Target account: role assumed by HarnessDelegateRole to run tag-gated chaos faults.
resource "aws_iam_role" "harness_target" {
  provider = aws.target
  count    = var.create_aws_iam ? 1 : 0

  name = local.execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.env.enable_chaos ? local.delegate_role_arn : "arn:aws:iam::${var.source_account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Application = var.app_slug
    Environment = var.env_key
    AccountRole = "target-execution"
  })
}

resource "aws_iam_role_policy" "harness_target_chaos" {
  provider = aws.target
  count    = var.create_aws_iam ? 1 : 0

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
