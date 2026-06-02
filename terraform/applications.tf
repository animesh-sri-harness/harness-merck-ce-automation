variable "applications" {
  description = "Harness projects (one Merck application each)."
  type = map(object({
    name             = string
    slug             = string
    description      = optional(string, "")
    enabled          = optional(bool, true)
    create_rbac      = optional(bool, true)
    admin_group_name = optional(string, "")
    dev_group_name   = optional(string, "")
    admin_emails     = optional(list(string), [])
    dev_emails       = optional(list(string), [])
    chaos_hub_name   = optional(string, "")
    chaos_hub_id     = optional(string, "")
  }))

  default = {
    app_a = {
      name             = "App"
      slug             = "app_a"
      description      = "Application A – dev / uat / prod chaos infrastructure"
      create_rbac      = true
      admin_group_name = "App A Admin"
      dev_group_name   = "App A Dev"
      admin_emails     = []
      dev_emails       = []
      chaos_hub_name   = "Merck Chaos Hub"
      chaos_hub_id     = "merck_chaos_hub"
    }
  }
}
