# ------------------------------------------------------------------------------
# Harness
# ------------------------------------------------------------------------------
variable "harness_endpoint" {
  type        = string
  description = "Harness Platform gateway URL."
  default     = "https://app.harness.io/gateway"
}

variable "harness_account_id" {
  type        = string
  description = "Harness account identifier."
  default     = "uZuUmmrnT4qQRx5XF0ZtkQ"
}

variable "harness_platform_api_key" {
  type        = string
  description = "Harness Platform API key (Account Admin or equivalent)."
  sensitive   = true
}

variable "org_identifier" {
  type        = string
  description = "Harness organization identifier."
  default     = "merck"
}

variable "org_name" {
  type    = string
  default = "Merck"
}

variable "project_identifier" {
  type    = string
  default = "app_a"
}

variable "project_name" {
  type    = string
  default = "App A"
}

variable "application_slug" {
  type        = string
  description = "Short name used in AWS IAM/KSA resource names (e.g. app_a)."
  default     = "app_a"
}

# ------------------------------------------------------------------------------
# AWS – control plane (EKS in play account)
# ------------------------------------------------------------------------------
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile for SSO (e.g. harness-impeng-play). Run: aws sso login --profile <name>"
  default     = "harness-impeng-play"
}

variable "aws_access_key_id" {
  type        = string
  sensitive   = true
  default     = null
  description = "Optional static key; ignored when aws_profile is set."
}

variable "aws_secret_access_key" {
  type        = string
  sensitive   = true
  default     = null
  description = "Optional static key; ignored when aws_profile is set."
}

variable "aws_session_token" {
  type        = string
  sensitive   = true
  default     = null
  description = "Optional session token; ignored when aws_profile is set."
}

variable "control_account_id" {
  type        = string
  description = "AWS account hosting the control EKS cluster (defaults to caller account if empty)."
  default     = ""
}

variable "name_prefix" {
  type        = string
  description = "Prefix for AWS resource names (VPC, EKS, node group)."
  default     = "merck-chaos"
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the Merck control EKS cluster to create."
  default     = "merck-poc-chaos-control-cluster"
}

variable "eks_cluster_version" {
  type    = string
  default = "1.31"
}

variable "eks_node_instance_type" {
  type        = string
  description = "Instance type for the control node group (t3.large fits 3 delegates on one node)."
  default     = "t3.large"
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

variable "chaos_control_namespace" {
  type    = string
  default = "merck-chaos-control"
}

# Target accounts per environment. For POC, default all to the control account.
variable "target_account_ids" {
  type = map(string)
  default = {
    dev  = "664418987337"
    uat  = "664418987337"
    prod = "664418987337"
  }
}

variable "create_rbac" {
  type        = bool
  description = "Create App A Admin/Dev user groups, roles, and role assignments."
  default     = true
}

variable "app_a_admin_emails" {
  type        = list(string)
  description = "Harness user emails to add to App A Admin group (optional; add via UI later)."
  default     = []
}

variable "app_a_dev_emails" {
  type        = list(string)
  description = "Harness user emails to add to App A Dev group (optional; add via UI later)."
  default     = []
}

variable "create_chaos_guard" {
  type        = bool
  description = "Create ChaosGuard rules via Terraform (Harness API often returns internal error; use chaos_guard_manual_steps output if false)."
  default     = false
}

variable "chaos_allowed_tag_key" {
  type        = string
  description = "Resource tag key gating AWS fault injection in target accounts."
  default     = "Chaos"
}

variable "chaos_allowed_tag_value" {
  type        = string
  description = "Resource tag value gating AWS fault injection in target accounts."
  default     = "allowed"
}

variable "harness_delegate_iam_role_name" {
  type        = string
  description = "Base name for control-account IAM roles (IRSA); suffixed per env (e.g. HarnessDelegateRole-dev)."
  default     = "HarnessDelegateRole"
}

variable "chaos_execution_iam_role_name" {
  type        = string
  description = "Base name for target-account IAM roles (fault injection); suffixed per env (e.g. ChaosExecutionRole-dev)."
  default     = "ChaosExecutionRole"
}

variable "create_aws_iam" {
  type        = bool
  description = "Create IAM roles/policies for cross-account chaos (IRSA + assume-role chain)."
  default     = true
}

variable "create_chaos_demo_ec2" {
  type        = bool
  description = "Provision a tagged demo EC2 instance for AWS chaos fault experiments."
  default     = true
}

variable "chaos_demo_instance_type" {
  type        = string
  description = "Instance type for the demo chaos target EC2."
  default     = "t3.micro"
}

variable "chaos_demo_instance_name" {
  type        = string
  description = "Name tag for the demo chaos target EC2."
  default     = "merck-chaos-demo-dev"
}

variable "chaos_demo_environment" {
  type        = string
  description = "Harness/AWS environment label for the demo EC2 (use dev for first experiments)."
  default     = "dev"
}

# ------------------------------------------------------------------------------
# Delegates (Helm on control EKS)
# ------------------------------------------------------------------------------
variable "install_delegates" {
  type        = bool
  description = "Install three org-scoped Harness delegates on the control EKS cluster."
  default     = true
}

variable "delegate_namespace_prefix" {
  type    = string
  default = "harness-delegate"
}

variable "harness_manager_endpoint" {
  type        = string
  description = "Harness manager URL for delegate Helm chart."
  default     = "https://app.harness.io"
}

variable "delegate_image" {
  type        = string
  description = "Delegate container image."
  default     = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:26.05.89101"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to Harness resources."
  default = {
    managed_by = "terraform"
    customer   = "merck"
    poc        = "chaos-engineering"
  }
}
