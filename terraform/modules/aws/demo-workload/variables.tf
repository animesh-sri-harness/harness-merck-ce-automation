variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "app_slug" { type = string }
variable "env_key" { type = string }
variable "instance_name" { type = string }
variable "instance_type" { type = string }
variable "platform" { type = any }
variable "tags" { type = map(string) }

variable "legacy_resource_naming" {
  description = "When true, use env-only demo EC2 IAM/SG names for single-app deployments."
  type        = bool
  default     = false
}
