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
    create_demo_ec2  = optional(bool, false)
    demo_ec2_env     = optional(string, "dev")
    demo_ec2_type    = optional(string, "t3.micro")
    demo_ec2_name    = optional(string, "")
    chaos_hub_name   = optional(string, "")
    chaos_hub_id     = optional(string, "")
  }))

  default = {
    app_a = {
      name             = "App A"
      slug             = "app_a"
      description      = "Application A – dev / uat / prod chaos infrastructure"
      create_rbac      = true
      admin_group_name = "App A Admin"
      dev_group_name   = "App A Dev"
      admin_emails     = []
      dev_emails       = []
      create_demo_ec2  = true
      demo_ec2_env     = "dev"
      demo_ec2_name    = "merck-chaos-demo-dev"
      chaos_hub_name   = "Merck Chaos Hub"
      chaos_hub_id     = "merck_chaos_hub"
    }
  }
}
