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
    chaos_control_namespace        = string
    rbac_resource_group            = string
    harness_delegate_iam_role_name = string
    chaos_execution_iam_role_name  = string
    chaos_allowed_tag_key          = string
    chaos_allowed_tag_value        = string
    aws_resource_prefix            = optional(string, "")
    eks_cluster_iam_role_name      = optional(string, "")
    eks_node_iam_role_name         = optional(string, "")
  })
  default = {
    chaos_namespace_prefix         = "merck-chaos"
    chaos_control_namespace        = "merck-chaos-control"
    rbac_resource_group            = "_all_project_level_resources"
    harness_delegate_iam_role_name = "HarnessDelegateRole"
    chaos_execution_iam_role_name  = "ChaosExecutionRole"
    chaos_allowed_tag_key          = "Chaos"
    chaos_allowed_tag_value        = "allowed"
    aws_resource_prefix            = "merck-chaos"
    eks_cluster_iam_role_name      = "merck-poc-chaos-eks-role"
    eks_node_iam_role_name         = "merck-poc-chaos-node-role"
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

variable "control_account_id" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "eks_cluster_name" {
  type    = string
  default = "merck-poc-chaos-control-cluster"
}

variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}

variable "eks_node_instance_type" {
  type    = string
  default = "t3.large"
}

variable "eks_node_desired_size" {
  type    = number
  default = 1
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 2
}

variable "install_delegates" {
  type    = bool
  default = true
}

variable "delegate_namespace_prefix" {
  type    = string
  default = "harness-delegate"
}

variable "delegate_image" {
  type    = string
  default = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:26.05.89101"
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
