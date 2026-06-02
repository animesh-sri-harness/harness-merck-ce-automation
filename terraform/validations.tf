check "harness_org_id" {
  assert {
    condition     = var.create_harness_org || var.harness_org_id != ""
    error_message = "Set harness_org_id to your existing Harness org identifier when create_harness_org is false."
  }
}

check "cross_account_target_accounts" {
  assert {
    condition = !var.create_aws_iam || alltrue([
      for k, v in local.environments_resolved :
      !try(v.enable_chaos, true) || try(v.target_account_id, null) != null
    ])
    error_message = "Set target_account_id (or default_target_account_id) for each environment so ChaosExecutionRole is created in the target account."
  }
}
