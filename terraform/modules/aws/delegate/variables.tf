variable "create_namespace" {
  type    = bool
  default = true
}

variable "helm_repository" {
  type    = string
  default = "https://app.harness.io/storage/harness-download/delegate-helm-chart/"
}

variable "namespace" { type = string }

variable "delegate_image" { type = string }

variable "delegate_name" { type = string }

variable "account_id" { type = string }

variable "delegate_token" {
  type      = string
  sensitive = true
}

variable "manager_endpoint" { type = string }

variable "deploy_mode" {
  type    = string
  default = "KUBERNETES"
}

variable "next_gen" {
  type    = bool
  default = true
}

variable "replicas" {
  type    = number
  default = 1
}

variable "upgrader_enabled" {
  type    = bool
  default = true
}

variable "proxy_user" {
  type    = string
  default = ""
}

variable "proxy_password" {
  type    = string
  default = ""
}

variable "proxy_host" {
  type    = string
  default = ""
}

variable "proxy_port" {
  type    = string
  default = ""
}

variable "proxy_scheme" {
  type    = string
  default = ""
}

variable "no_proxy" {
  type    = string
  default = ""
}

variable "init_script" {
  type    = string
  default = ""
}

variable "values" {
  type    = string
  default = ""
}
