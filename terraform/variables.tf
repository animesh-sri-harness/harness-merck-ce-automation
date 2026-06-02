variable "harness_endpoint" {
  type    = string
  default = "https://app.harness.io/gateway"
}

variable "harness_account_id" {
  type    = string
  default = "uZuUmmrnT4qQRx5XF0ZtkQ"
}

variable "harness_platform_api_key" {
  type      = string
  sensitive = true
}

variable "harness_manager_endpoint" {
  type    = string
  default = "https://app.harness.io"
}

variable "org" {
  description = "Harness organization settings."
  type = object({
    identifier = string
    name       = string
    prefix     = string
  })
  default = {
    identifier = "merck"
    name       = "Merck"
    prefix     = "merck"
  }
}

variable "platform" {
  description = "Shared platform naming for AWS/K8s chaos resources."
  type = object({
    chaos_namespace_prefix         = string
    rbac_resource_group            = string
    harness_delegate_iam_role_name = string
    chaos_execution_iam_role_name  = string
    chaos_allowed_tag_key          = string
    chaos_allowed_tag_value        = string
    aws_resource_prefix            = optional(string, "")
  })
  default = {
    chaos_namespace_prefix         = "merck-chaos"
    rbac_resource_group            = "_all_project_level_resources"
    harness_delegate_iam_role_name = "HarnessDelegateRole"
    chaos_execution_iam_role_name  = "ChaosExecutionRole"
    chaos_allowed_tag_key          = "Chaos"
    chaos_allowed_tag_value        = "allowed"
    aws_resource_prefix            = "merck-chaos"
  }
}

variable "default_tags" {
  description = "Tags applied to Harness and AWS resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    customer   = "merck"
    poc        = "chaos-engineering"
  }
}

variable "chaos_guard_destructive_faults" {
  description = "Faults blocked by ChaosGuard when chaos_guard_block = true."
  type        = list(string)
  default = [
    "pod-delete",
    "container-kill",
    "ec2-stop-by-id",
    "ec2-stop-by-tag",
  ]
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI SSO profile. Run: aws sso login --profile <name>"
  default     = "harness-impeng-play"
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
  default   = null
}

variable "aws_session_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "create_harness_org" {
  description = "Create a new Harness organization. Set false when using an existing org."
  type        = bool
  default     = false
}

variable "harness_org_id" {
  description = "Existing Harness org identifier (required when create_harness_org is false)."
  type        = string
  default     = ""
}

variable "source_account_id" {
  description = "Default AWS account ID for control EKS clusters and HarnessDelegateRole. Per-environment source_account_id overrides this."
  type        = string
  default     = ""
}

variable "default_target_account_id" {
  description = "Default AWS account ID for ChaosExecutionRole (target). Required per environment via target_account_id or this default when create_aws_iam is true."
  type        = string
  default     = ""
}

variable "aws_deploy_assume_role_arns" {
  description = "Optional IAM role ARNs for Terraform to assume when creating resources in source/target accounts (dev/uat/prod)."
  type = object({
    source = optional(object({
      dev  = optional(string, "")
      uat  = optional(string, "")
      prod = optional(string, "")
    }), {})
    target = optional(object({
      dev  = optional(string, "")
      uat  = optional(string, "")
      prod = optional(string, "")
    }), {})
  })
  default = {}
}

variable "control_account_id" {
  description = "Deprecated: use source_account_id."
  type        = string
  default     = ""
}

variable "create_delegate_tokens" {
  description = "Create Harness delegate tokens (only required when Terraform installs delegates)."
  type        = bool
  default     = false
}

variable "create_aws_iam" {
  type    = bool
  default = true
}

variable "create_chaos_guard" {
  type    = bool
  default = false
}

variable "create_rbac" {
  type    = bool
  default = true
}
