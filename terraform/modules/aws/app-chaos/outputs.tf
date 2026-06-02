output "env_key" {
  value = var.env_key
}

output "control_role_arn" {
  value = try(aws_iam_role.harness_control[0].arn, null)
}

output "target_role_arn" {
  value = try(aws_iam_role.harness_target[0].arn, null)
}

output "service_account" {
  value = var.env.enable_chaos ? "${var.env.k8s_namespace}/${local.ksa_name}" : null
}
