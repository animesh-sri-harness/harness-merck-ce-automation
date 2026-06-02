variable "org_id" { type = string }
variable "app_key" { type = string }
variable "app" { type = any }
variable "environments" { type = any }
variable "tags_set" { type = list(string) }
variable "platform" { type = any }

variable "create_rbac" { type = bool }
variable "create_chaos_guard" { type = bool }
variable "chaos_guard_destructive_faults" { type = list(string) }

variable "execution_role_arns" {
  description = "Map env_key => ChaosExecutionRole ARN for AWS connector cross_account_access."
  type        = map(string)
}

variable "aws_region" { type = string }
