variable "app_key" { type = string }
variable "app_slug" { type = string }
variable "env_key" { type = string }
variable "env" { type = any }
variable "platform" { type = any }
variable "tags" { type = map(string) }

variable "create_aws_iam" { type = bool }

variable "source_account_id" {
  description = "AWS account hosting the control EKS cluster and HarnessDelegateRole."
  type        = string
}

variable "target_account_id" {
  description = "AWS account where ChaosExecutionRole is created."
  type        = string
}

variable "oidc_provider_arn" { type = string }
variable "oidc_issuer_host" { type = string }

variable "iam_role_suffix" {
  description = "Suffix for IAM role names (env-only for single-app, app-env for multi-app)."
  type        = string
}

variable "legacy_resource_naming" {
  description = "When true, keep env-only K8s/IAM inline policy names for single-app deployments."
  type        = bool
  default     = false
}
