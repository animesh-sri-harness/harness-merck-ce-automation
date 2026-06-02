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

variable "harness_manager_endpoint" {
  type    = string
  default = "https://app.harness.io"
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
