locals {
  aws_app_chaos_modules = merge(
    module.aws_app_chaos_dev,
    module.aws_app_chaos_uat,
    module.aws_app_chaos_prod,
  )
}

output "harness_org_id" {
  value = local.harness_org_id
}

output "harness_projects" {
  value = { for k, m in module.harness_application : k => m.project_id }
}

output "harness_environments" {
  value = { for k, m in module.harness_application : k => m.environment_ids }
}

output "harness_infrastructures" {
  value = { for k, m in module.harness_application : k => m.infrastructure_ids }
}

output "delegate_names" {
  value = [for k, v in local.environments_resolved : v.delegate_name]
}

output "harness_delegate_role_arns" {
  description = "HarnessDelegateRole ARNs in source (control) accounts."
  value = {
    for k, m in local.aws_app_chaos_modules : k => m.control_role_arn
    if m.control_role_arn != null
  }
}

output "chaos_execution_role_arns" {
  description = "ChaosExecutionRole ARNs in target accounts."
  value = {
    for k, m in local.aws_app_chaos_modules : k => m.target_role_arn
    if m.target_role_arn != null
  }
}

output "chaos_service_accounts" {
  description = "Expected KSA paths Merck must create on source EKS (namespace/serviceaccount). Not created by Terraform."
  value = {
    for k, m in local.aws_app_chaos_modules : k => m.service_account
    if m.service_account != null
  }
}

output "harness_rbac" {
  value = { for k, m in module.harness_application : k => m.rbac }
}

output "applications_configured" {
  description = "Applications from applications.tf"
  value       = [for k, v in local.applications_enabled : "${k} (${v.name})"]
}

output "environments_configured" {
  description = "Environments from environments.tf"
  value       = keys(local.environments_resolved)
}

output "environment_source_eks_clusters" {
  description = "Resolved control (source) EKS cluster name per environment."
  value       = { for k, v in local.environments_resolved : k => v.source_eks_cluster_name }
}

output "environment_source_eks_regions" {
  description = "Resolved AWS region for each environment's control EKS cluster."
  value       = { for k, v in local.environments_resolved : k => v.source_eks_region }
}

output "environment_account_ids" {
  description = "Source (control) and target AWS account IDs per environment."
  value = {
    for k, v in local.environments_resolved : k => {
      source_account_id = v.source_account_id
      target_account_id = v.target_account_id
    }
  }
}

output "harness_project_id" {
  description = "Primary project slug when exactly one application is enabled."
  value       = local.single_application ? values(module.harness_application)[0].project_id : null
}

output "harness_control_role_arns" {
  description = "Per-env HarnessDelegateRole ARNs in source accounts (single-app: keyed by env)."
  value = local.single_application ? {
    for pair_key, m in local.aws_app_chaos_modules :
    split("/", pair_key)[1] => m.control_role_arn
    if startswith(pair_key, "${keys(local.applications_enabled)[0]}/") && m.control_role_arn != null
  } : {}
}

output "harness_target_role_arns" {
  description = "Per-env ChaosExecutionRole ARNs in target accounts (single-app: keyed by env)."
  value = local.single_application ? {
    for pair_key, m in local.aws_app_chaos_modules :
    split("/", pair_key)[1] => m.target_role_arn
    if startswith(pair_key, "${keys(local.applications_enabled)[0]}/") && m.target_role_arn != null
  } : {}
}

output "merck_tsa_compliance" {
  value = {
    "1_rbac"                    = var.create_rbac ? "OK – per-app Admin/Dev → HarnessDelegateRole/ChaosExecutionRole" : "SKIPPED"
    "2_project_structure"       = "OK – org ${local.harness_org_id}, apps ${join(", ", keys(local.applications_enabled))}, envs ${join(", ", keys(local.environments_resolved))}"
    "3_chaosguard_governance"   = var.create_chaos_guard ? "OK – per-app block rules for guarded envs" : "MANUAL – set create_chaos_guard = true or configure in UI"
    "4_delegates_per_env"       = "EXTERNAL – Merck installs delegates per env cluster"
    "5_ksa_transient_pods"      = "MANUAL – Merck creates ksa-{app_slug}-{env} in ${var.platform.chaos_namespace_prefix}-{env} on source EKS; see chaos_service_accounts output"
    "6_irsa_oidc_control_role"  = var.create_aws_iam ? "OK – ${var.platform.harness_delegate_iam_role_name}-{env} in source accounts" : "SKIPPED"
    "7_control_to_target_sts"   = var.create_aws_iam ? "OK – source HarnessDelegateRole → target ChaosExecutionRole (cross-account)" : "SKIPPED"
    "8_target_tag_gated_faults" = var.create_aws_iam ? "OK – ${var.platform.chaos_allowed_tag_key}=${var.platform.chaos_allowed_tag_value}" : "SKIPPED"
  }
}

output "post_apply_checklist" {
  value = <<-EOT
    1. aws sso login --profile ${var.aws_profile}
    2. Harness → Org ${var.org.name} (${local.harness_org_id}) → verify delegates Connected per environment
    3. terraform output harness_control_role_arns / harness_target_role_arns
    4. Edit applications.tf or environments.tf to add apps/envs
  EOT
}
