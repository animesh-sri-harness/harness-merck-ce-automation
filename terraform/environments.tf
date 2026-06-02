variable "environments" {
  description = "Deployment environments shared across all applications."
  type = map(object({
    harness_type           = string
    enable_chaos           = optional(bool, true)
    chaos_guard_block      = optional(bool, false)
    target_account_id      = optional(string, "")
    delegate_name          = optional(string, "")
    delegate_tags          = optional(list(string), [])
    env_identifier         = optional(string, "")
    infra_identifier       = optional(string, "")
    k8s_namespace          = optional(string, "")
    delegate_autoscale_max = optional(number, 3)
  }))

  default = {
    dev = {
      harness_type      = "PreProduction"
      enable_chaos      = true
      chaos_guard_block = false
    }
    uat = {
      harness_type      = "PreProduction"
      enable_chaos      = true
      chaos_guard_block = true
    }
    prod = {
      harness_type      = "Production"
      enable_chaos      = true
      chaos_guard_block = true
    }
  }
}
