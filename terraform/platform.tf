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
