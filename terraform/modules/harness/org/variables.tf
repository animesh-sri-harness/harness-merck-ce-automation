variable "harness_account_id" { type = string }
variable "org" { type = any }
variable "tags_set" { type = list(string) }
variable "environments" { type = any }

variable "create_org" {
  type    = bool
  default = false
}

variable "existing_org_id" {
  type    = string
  default = ""
}

variable "create_delegate_tokens" {
  type    = bool
  default = false
}
