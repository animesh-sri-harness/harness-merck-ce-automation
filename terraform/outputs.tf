output "eks_cluster_name" {
  description = "Merck control EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Merck control EKS API endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Command to configure kubectl for the control cluster."
  value       = "aws sso login --profile ${var.aws_profile} && aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile ${var.aws_profile}"
}

output "harness_org_id" {
  value = harness_platform_organization.merck.id
}

output "harness_project_id" {
  value = harness_platform_project.app_a.id
}

output "harness_environments" {
  value = { for k, v in harness_platform_environment.env : k => v.id }
}

output "harness_infrastructures" {
  value = { for k, v in harness_platform_infrastructure.env : k => v.id }
}

output "delegate_names" {
  value = { for k, v in local.environments : k => v.delegate_name }
}

output "delegate_tags" {
  value = { for k, v in local.environments : k => v.delegate_tags }
}

output "harness_delegate_role_arns" {
  description = "HarnessDelegateRole ARNs per environment (control account, IRSA)."
  value       = { for k, v in aws_iam_role.harness_control : k => v.arn }
}

output "chaos_execution_role_arns" {
  description = "ChaosExecutionRole ARNs per environment (target account fault injection)."
  value       = { for k, v in aws_iam_role.harness_target : k => v.arn }
}

# Deprecated aliases – use harness_delegate_role_arns / chaos_execution_role_arns.
output "harness_control_role_arns" {
  value = { for k, v in aws_iam_role.harness_control : k => v.arn }
}

output "harness_target_role_arns" {
  value = { for k, v in aws_iam_role.harness_target : k => v.arn }
}

output "chaos_service_accounts" {
  value = { for k, v in kubernetes_service_account.chaos_executor : k => "${v.metadata[0].namespace}/${v.metadata[0].name}" }
}

output "harness_rbac" {
  description = "App A RBAC identifiers (when create_rbac = true)."
  value = var.create_rbac ? {
    admin_group    = harness_platform_usergroup.app_a_admin[0].identifier
    dev_group      = harness_platform_usergroup.app_a_dev[0].identifier
    delegate_role  = harness_platform_roles.harness_delegate_role[0].identifier
    execution_role = harness_platform_roles.chaos_execution_role[0].identifier
    resource_group = local.rbac_resource_group
  } : null
}

output "merck_tsa_compliance" {
  description = "Requirement-by-requirement compliance status for Merck TSA chaos architecture."
  value = {
    "1_rbac_user_groups_roles"  = var.create_rbac ? "OK – App A Admin → HarnessDelegateRole; App A Dev → ChaosExecutionRole on ${local.rbac_resource_group}" : "SKIPPED – set create_rbac = true"
    "2_project_structure"       = "OK – org ${local.org_id}, project ${local.project_id}, infra dev/uat/prod"
    "3_chaosguard_governance"   = var.create_chaos_guard ? "OK – destructive faults blocked in uat/prod; dev allowed" : "MANUAL – create UAT/Prod block rule in Harness UI (see chaos_guard_manual_steps output)"
    "4_delegates_per_env"       = var.install_delegates ? "OK – merck-delegate-dev/uat/prod on control EKS" : "SKIPPED"
    "5_ksa_transient_pods"      = "OK – ksa-${local.application_slug_k8s}-{dev,uat,prod} in merck-chaos-{env} namespaces"
    "6_irsa_oidc_control_role"  = var.create_aws_iam ? "OK – IRSA trust → ${var.harness_delegate_iam_role_name}-{env} per env" : "SKIPPED"
    "7_control_to_target_sts"   = var.create_aws_iam ? "OK – ${var.harness_delegate_iam_role_name} may sts:AssumeRole only into ${var.chaos_execution_iam_role_name}" : "SKIPPED"
    "8_target_tag_gated_faults" = var.create_aws_iam ? "OK – target roles scoped to ${var.chaos_allowed_tag_key}=${var.chaos_allowed_tag_value} on EC2/SSM/RDS/Lambda" : "SKIPPED"
    "poc_caveats" = [
      "Target roles deployed in same AWS account (${local.control_account_id}); Merck prod uses separate spoke accounts per env.",
      "Tag workloads with ${var.chaos_allowed_tag_key}=${var.chaos_allowed_tag_value} before AWS faults can reach them.",
      "Add user emails via app_a_admin_emails / app_a_dev_emails or Harness UI → Access Control.",
    ]
  }
}

output "chaos_guard_manual_steps" {
  description = "Manual ChaosGuard setup when Terraform API fails (Merck TSA §3)."
  value       = <<-EOT
    Harness UI → Project App A → Chaos Engineering → Security Governance:

    1. Create condition "block-uat-destructive-faults":
       - Infrastructure: UAT chaos infra (${try(harness_chaos_infrastructure_v2.env["uat"].id, "infra_uat")})
       - Faults: destructive faults (pod-delete, container-kill, ec2-stop, etc.)

    2. Create condition "block-prod-destructive-faults":
       - Infrastructure: Prod chaos infra (${try(harness_chaos_infrastructure_v2.env["prod"].id, "infra_prod")})
       - Same destructive fault list

    3. Create rule "merck-block-uat-prod-destructive-chaos":
       - Attach both conditions
       - Enable 24/7 time window
       - Dev infra remains unblocked (allowed mapping)

    Re-try Terraform later with create_chaos_guard = true when Harness API is fixed.
  EOT
}

output "chaos_demo_ec2" {
  description = "Demo EC2 target for AWS chaos experiments (when create_chaos_demo_ec2 = true)."
  value = var.create_chaos_demo_ec2 ? {
    instance_id        = aws_instance.chaos_demo[0].id
    instance_name      = var.chaos_demo_instance_name
    public_ip          = aws_instance.chaos_demo[0].public_ip
    private_ip         = aws_instance.chaos_demo[0].private_ip
    tags               = aws_instance.chaos_demo[0].tags
    aws_connector      = "aws_${var.chaos_demo_environment}"
    execution_role_arn = aws_iam_role.harness_target[var.chaos_demo_environment].arn
  } : null
}

output "ec2_chaos_demo_steps" {
  description = "Steps to run a sample EC2 chaos experiment in Harness."
  value = try(<<-EOT
    Prerequisites:
      aws sso login --profile ${var.aws_profile}
      Confirm delegate merck-delegate-${var.chaos_demo_environment} is Connected in Harness UI.

    Demo target (Terraform-provisioned):
      Instance ID: ${aws_instance.chaos_demo[0].id}
      Name tag:    ${var.chaos_demo_instance_name}
      Tag:         ${var.chaos_allowed_tag_key}=${var.chaos_allowed_tag_value}

    Harness UI → Project App A → Chaos Engineering → Experiments → New Experiment:

    1. Name: merck-ec2-stop-demo
    2. Environment: ${upper(var.chaos_demo_environment)} (env_${var.chaos_demo_environment})
    3. Infrastructure: infra_${var.chaos_demo_environment} (chaos-infra-${var.chaos_demo_environment})
    4. Add fault: EC2 Stop By ID (or EC2 Stop By Tag)
       - AWS connector: aws_${var.chaos_demo_environment}
       - Region: ${var.aws_region}
       - Instance ID: ${aws_instance.chaos_demo[0].id}
         OR tag filter: ${var.chaos_allowed_tag_key}=${var.chaos_allowed_tag_value}
    5. Run experiment → instance stops → verify in AWS Console → start instance again

    Credential chain:
      KSA → HarnessDelegateRole-${var.chaos_demo_environment} → ChaosExecutionRole-${var.chaos_demo_environment}
  EOT
  , "Set create_chaos_demo_ec2 = true and terraform apply to provision a demo EC2 target.")
}

output "post_apply_checklist" {
  value = <<-EOT
    1. Run: aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
    2. Harness UI → Org Merck → Delegates: confirm merck-delegate-dev/uat/prod are Connected.
    3. Project App A → Access Control: verify App A Admin / App A Dev groups and role bindings.
    4. Project App A → Chaos → Security Governance: verify UAT/Prod destructive-fault block rule is enabled.
    5. Demo EC2: terraform output chaos_demo_ec2  (tagged ${var.chaos_allowed_tag_key}=${var.chaos_allowed_tag_value})
    6. EC2 chaos: terraform output ec2_chaos_demo_steps
    7. K8s chaos: pod-delete in merck-chaos-dev using ksa-${local.application_slug_k8s}-dev
  EOT
}
