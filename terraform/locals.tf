locals {
  org_id     = var.org_identifier
  project_id = var.project_identifier

  control_account_id = var.control_account_id != "" ? var.control_account_id : data.aws_caller_identity.current.account_id

  tags_set = [for k, v in var.tags : "${k}=${v}"]

  # Per Merck: Dev/UAT allowed for chaos; Prod blocked via ChaosGuard.
  environments = {
    dev = {
      harness_type     = "PreProduction"
      delegate_name    = "merck-delegate-dev"
      delegate_tags    = ["merck-delegate-dev", "env:dev"]
      infra_identifier = "infra_dev"
      env_identifier   = "env_dev"
      k8s_namespace    = "merck-chaos-dev"
      enable_chaos     = true
    }
    uat = {
      harness_type     = "PreProduction"
      delegate_name    = "merck-delegate-uat"
      delegate_tags    = ["merck-delegate-uat", "env:uat"]
      infra_identifier = "infra_uat"
      env_identifier   = "env_uat"
      k8s_namespace    = "merck-chaos-uat"
      enable_chaos     = true
    }
    prod = {
      harness_type     = "Production"
      delegate_name    = "merck-delegate-prod"
      delegate_tags    = ["merck-delegate-prod", "env:prod"]
      infra_identifier = "infra_prod"
      env_identifier   = "env_prod"
      k8s_namespace    = "merck-chaos-prod"
      enable_chaos     = true # infra registered; ChaosGuard blocks experiment execution
    }
  }

  env_keys_chaos_enabled = [for k, v in local.environments : k if v.enable_chaos]

  # K8s names must be RFC 1123 (no underscores).
  application_slug_k8s = replace(var.application_slug, "_", "-")

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer_host  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Start with pod-delete only; Harness API rejects some multi-fault conditions (expand in UI).
  chaos_guard_destructive_faults = [
    "pod-delete",
  ]

  chaos_guard_blocked_envs = ["uat", "prod"]
}
