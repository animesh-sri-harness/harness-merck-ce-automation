variable "environments" {
  description = "Deployment environments shared across all applications."
  type = map(object({
    harness_type            = string
    enable_chaos            = optional(bool, true)
    chaos_guard_block       = optional(bool, false)
    source_account_id       = optional(string, "")
    target_account_id       = optional(string, "")
    source_eks_cluster_name = optional(string, "")
    source_eks_region       = optional(string, "")
    delegate_name           = optional(string, "")
    delegate_tags           = optional(list(string), [])
    env_identifier          = optional(string, "")
    infra_identifier        = optional(string, "")
    k8s_namespace           = optional(string, "")
    delegate_autoscale_max  = optional(number, 3)
  }))

  default = {
    dev = {
      harness_type            = "PreProduction"
      enable_chaos            = true
      chaos_guard_block       = false
      source_account_id       = ""
      target_account_id       = ""
      source_eks_cluster_name = ""
    }
    uat = {
      harness_type            = "PreProduction"
      enable_chaos            = true
      chaos_guard_block       = true
      source_account_id       = ""
      target_account_id       = ""
      source_eks_cluster_name = ""
    }
    prod = {
      harness_type            = "Production"
      enable_chaos            = true
      chaos_guard_block       = true
      source_account_id       = ""
      target_account_id       = ""
      source_eks_cluster_name = ""
    }
  }

  validation {
    condition     = !var.create_aws_iam || alltrue([for k, v in var.environments : !try(v.enable_chaos, true) || try(v.source_eks_cluster_name, "") != ""])
    error_message = "When create_aws_iam is true, set source_eks_cluster_name for each environment with enable_chaos=true (required for IRSA on the control EKS cluster)."
  }

  validation {
    condition = !var.create_aws_iam || alltrue([
      for k, v in var.environments :
      !try(v.enable_chaos, true) || (
        try(v.target_account_id, "") != "" || var.default_target_account_id != ""
      )
    ])
    error_message = "When create_aws_iam is true, set target_account_id per environment (or default_target_account_id) for ChaosExecutionRole in target accounts."
  }
}
