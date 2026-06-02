output "env_key" {
  value = var.env_key
}

output "source_account_id" {
  value = var.source_account_id
}

output "target_account_id" {
  value = var.target_account_id
}

output "control_role_arn" {
  value = try(aws_iam_role.harness_control[0].arn, local.delegate_role_arn)
}

output "target_role_arn" {
  value = try(aws_iam_role.harness_target[0].arn, local.execution_role_arn)
}

output "service_account" {
  value = var.env.enable_chaos ? "${var.env.k8s_namespace}/${local.ksa_name}" : null
}
