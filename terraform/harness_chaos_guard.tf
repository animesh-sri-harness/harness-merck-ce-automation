# ChaosGuard: allow Dev; block destructive faults in UAT and Prod (Merck TSA §3).
resource "harness_chaos_security_governance_condition" "block_uat_prod_destructive" {
  for_each = var.create_chaos_guard ? toset(local.chaos_guard_blocked_envs) : toset([])

  depends_on = [
    harness_platform_infrastructure.env,
    harness_chaos_infrastructure_v2.env,
  ]

  name        = "block-${each.key}-destructive-faults"
  description = "Match destructive faults targeting ${upper(each.key)} chaos infrastructure"
  org_id      = local.org_id
  project_id  = local.project_id
  infra_type  = "KubernetesV2"

  k8s_spec {
    infra_spec {
      operator  = "EQUAL_TO"
      infra_ids = ["${harness_platform_environment.env[each.key].id}/${harness_chaos_infrastructure_v2.env[each.key].id}"]
    }
  }

  dynamic "fault_spec" {
    for_each = [1]
    content {
      operator = "EQUAL_TO"
      dynamic "faults" {
        for_each = local.chaos_guard_destructive_faults
        content {
          fault_type = "FAULT"
          name       = faults.value
        }
      }
    }
  }

  tags = ["merck", "chaosguard", "env:${each.key}"]
}

resource "harness_chaos_security_governance_rule" "merck_uat_prod_block" {
  count = var.create_chaos_guard ? 1 : 0

  depends_on = [harness_chaos_security_governance_condition.block_uat_prod_destructive]

  name        = "merck-block-uat-prod-destructive-chaos"
  description = "Block destructive chaos faults in UAT/Prod; Dev flows through as allowed"
  org_id      = local.org_id
  project_id  = local.project_id
  is_enabled  = true
  condition_ids = [
    for env in local.chaos_guard_blocked_envs :
    harness_chaos_security_governance_condition.block_uat_prod_destructive[env].id
  ]
  user_group_ids = []

  time_windows {
    time_zone  = "UTC"
    start_time = 0
    duration   = "24h"
  }

  tags = concat(local.tags_set, ["chaosguard=uat-prod-block"])
}
