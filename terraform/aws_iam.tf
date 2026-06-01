# HarnessDelegateRole (control account) – assumed by KSA via IRSA (per env namespace).
resource "aws_iam_role" "harness_control" {
  for_each = var.create_aws_iam ? { for k, v in local.environments : k => v if v.enable_chaos } : {}

  depends_on = [module.eks]

  name = "${var.harness_delegate_iam_role_name}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:${each.value.k8s_namespace}:ksa-${local.application_slug_k8s}-${each.key}"
        }
      }
    }]
  })

  tags = merge(var.tags, { Environment = each.key })
}

resource "aws_iam_role_policy" "harness_control_assume_target" {
  for_each = var.create_aws_iam ? { for k, v in local.environments : k => v if v.enable_chaos } : {}

  name = "assume-target-${each.key}"
  role = aws_iam_role.harness_control[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.harness_target[each.key].arn
    }]
  })
}

# ChaosExecutionRole (target account) – trusts HarnessDelegateRole; tag-gated fault injection.
resource "aws_iam_role" "harness_target" {
  for_each = var.create_aws_iam ? local.environments : {}

  name = "${var.chaos_execution_iam_role_name}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = contains(keys(aws_iam_role.harness_control), each.key) ? aws_iam_role.harness_control[each.key].arn : "arn:aws:iam::${local.control_account_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, { Environment = each.key })
}

resource "aws_iam_role_policy" "harness_target_chaos" {
  for_each = var.create_aws_iam ? local.environments : {}

  name = "chaos-tag-gated-faults"
  role = aws_iam_role.harness_target[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DiscoverResources"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ssm:DescribeInstanceInformation",
          "ssm:ListCommandInvocations",
          "rds:DescribeDBInstances",
          "lambda:ListFunctions",
          "lambda:GetFunction",
        ]
        Resource = "*"
      },
      {
        Sid    = "TagGatedEC2Faults"
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:RebootInstances",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.chaos_allowed_tag_key}" = var.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid    = "TagGatedSSMFaults"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ssm:resourceTag/${var.chaos_allowed_tag_key}" = var.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid    = "TagGatedRDSFaults"
        Effect = "Allow"
        Action = [
          "rds:RebootDBInstance",
          "rds:StopDBInstance",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.chaos_allowed_tag_key}" = var.chaos_allowed_tag_value
          }
        }
      },
      {
        Sid    = "TagGatedLambdaFaults"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:UpdateFunctionConfiguration",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${var.chaos_allowed_tag_key}" = var.chaos_allowed_tag_value
          }
        }
      },
    ]
  })
}
