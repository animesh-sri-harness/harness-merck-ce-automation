output "eks_cluster_name" {
  value = module.control_plane.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.control_plane.cluster_endpoint
}

output "configure_kubectl" {
  value = "aws sso login --profile ${var.aws_profile} && aws eks update-kubeconfig --region ${var.aws_region} --name ${module.control_plane.cluster_name} --profile ${var.aws_profile}"
}

output "harness_org_id" {
  value = module.harness_org.org_id
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
  value = module.control_plane.delegate_names
}

output "harness_delegate_role_arns" {
  value = {
    for k, m in module.aws_app_chaos : k => m.control_role_arn
    if m.control_role_arn != null
  }
}

output "chaos_execution_role_arns" {
  value = {
    for k, m in module.aws_app_chaos : k => m.target_role_arn
    if m.target_role_arn != null
  }
}

output "chaos_service_accounts" {
  value = {
    for k, m in module.aws_app_chaos : k => m.service_account
    if m.service_account != null
  }
}

output "harness_rbac" {
  value = { for k, m in module.harness_application : k => m.rbac }
}

output "chaos_demo_ec2" {
  value = {
    for app_key, m in module.aws_demo_workload : app_key => {
      instance_id   = m.instance_id
      public_ip     = m.public_ip
      private_ip    = m.private_ip
      app_slug      = local.applications_enabled[app_key].slug
      env_key       = local.applications_enabled[app_key].demo_ec2_env
      aws_connector = "aws_${local.applications_enabled[app_key].demo_ec2_env}"
    }
  }
}

output "applications_configured" {
  description = "Applications from applications.tf"
  value       = [for k, v in local.applications_enabled : "${k} (${v.name})"]
}

output "environments_configured" {
  description = "Environments from environments.tf"
  value       = keys(local.environments_resolved)
}

output "harness_project_id" {
  description = "Primary project slug when exactly one application is enabled."
  value       = local.single_application ? values(module.harness_application)[0].project_id : null
}

output "harness_control_role_arns" {
  description = "Per-env HarnessDelegateRole ARNs (single-app: keyed by env)."
  value = local.single_application ? {
    for pair_key, m in module.aws_app_chaos :
    split("/", pair_key)[1] => m.control_role_arn
    if startswith(pair_key, "${keys(local.applications_enabled)[0]}/") && m.control_role_arn != null
  } : {}
}

output "harness_target_role_arns" {
  description = "Per-env ChaosExecutionRole ARNs (single-app: keyed by env)."
  value = local.single_application ? {
    for pair_key, m in module.aws_app_chaos :
    split("/", pair_key)[1] => m.target_role_arn
    if startswith(pair_key, "${keys(local.applications_enabled)[0]}/") && m.target_role_arn != null
  } : {}
}

output "ec2_chaos_demo_steps" {
  description = "Step-by-step EC2 chaos demo for the first app with create_demo_ec2 = true."
  value = length(module.aws_demo_workload) > 0 ? (
    local.demo_ec2_steps[keys(module.aws_demo_workload)[0]]
  ) : "No demo EC2 configured. Set create_demo_ec2 = true in applications.tf."
}

locals {
  demo_ec2_steps = {
    for app_key, m in module.aws_demo_workload : app_key => <<-EOT
      Prerequisites:
        aws sso login --profile ${var.aws_profile}
        Confirm delegate ${local.environments_resolved[local.applications_enabled[app_key].demo_ec2_env].delegate_name} is Connected in Harness UI.

      Demo target (Terraform-provisioned):
        Instance ID: ${m.instance_id}
        Name tag:    ${local.applications_enabled[app_key].demo_ec2_name != "" ? local.applications_enabled[app_key].demo_ec2_name : m.instance_id}
        Tag:         ${var.platform.chaos_allowed_tag_key}=${var.platform.chaos_allowed_tag_value}

      Harness UI → Project ${local.applications_enabled[app_key].name} → Chaos Engineering → Experiments → New Experiment:
        1. Environment: ${upper(local.applications_enabled[app_key].demo_ec2_env)}
        2. AWS connector: aws_${local.applications_enabled[app_key].demo_ec2_env}
        3. Fault: EC2 Stop By ID — Instance ID: ${m.instance_id}
        4. Credential chain: KSA → HarnessDelegateRole → ChaosExecutionRole
    EOT
  }
}

output "merck_tsa_compliance" {
  value = {
    "1_rbac"                    = var.create_rbac ? "OK – per-app Admin/Dev → HarnessDelegateRole/ChaosExecutionRole" : "SKIPPED"
    "2_project_structure"       = "OK – org ${local.org_id}, apps ${join(", ", keys(local.applications_enabled))}, envs ${join(", ", keys(local.environments_resolved))}"
    "3_chaosguard_governance"   = var.create_chaos_guard ? "OK – per-app block rules for guarded envs" : "MANUAL – set create_chaos_guard = true or configure in UI"
    "4_delegates_per_env"       = var.install_delegates ? "OK – ${var.org.prefix}-delegate-{env} on control EKS" : "SKIPPED"
    "5_ksa_transient_pods"      = "OK – ksa-{app_slug}-{env} in ${var.platform.chaos_namespace_prefix}-{env} namespaces"
    "6_irsa_oidc_control_role"  = var.create_aws_iam ? "OK – ${var.platform.harness_delegate_iam_role_name}-{suffix}" : "SKIPPED"
    "7_control_to_target_sts"   = var.create_aws_iam ? "OK – AssumeRole into ${var.platform.chaos_execution_iam_role_name}-{suffix}" : "SKIPPED"
    "8_target_tag_gated_faults" = var.create_aws_iam ? "OK – ${var.platform.chaos_allowed_tag_key}=${var.platform.chaos_allowed_tag_value}" : "SKIPPED"
  }
}

output "post_apply_checklist" {
  value = <<-EOT
    1. aws sso login --profile ${var.aws_profile}
    2. terraform output configure_kubectl
    3. Harness → Org ${var.org.name} → Delegates: verify Connected
    4. Edit applications.tf or environments.tf to add apps/envs
    5. Demo EC2: terraform output chaos_demo_ec2
    6. EC2 demo steps: terraform output ec2_chaos_demo_steps
  EOT
}
