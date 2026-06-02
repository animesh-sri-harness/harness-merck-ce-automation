variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "aws_region" { type = string }
variable "tags" { type = map(string) }

variable "eks_cluster_name" { type = string }
variable "eks_cluster_version" { type = string }
variable "eks_node_instance_type" { type = string }
variable "eks_node_desired_size" { type = number }
variable "eks_node_min_size" { type = number }
variable "eks_node_max_size" { type = number }

variable "environments" { type = any }
variable "install_delegates" { type = bool }

variable "harness_account_id" { type = string }
variable "harness_manager_endpoint" { type = string }
variable "delegate_image" { type = string }
variable "delegate_namespace_prefix" { type = string }
variable "delegate_tokens" { type = map(string) }

variable "chaos_control_namespace" { type = string }

variable "eks_cluster_iam_role_name" {
  type    = string
  default = ""
}

variable "eks_node_iam_role_name" {
  type    = string
  default = ""
}
