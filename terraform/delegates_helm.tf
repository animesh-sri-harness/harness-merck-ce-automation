module "delegate" {
  for_each = var.install_delegates ? local.environments : {}

  source  = "harness/harness-delegate/kubernetes"
  version = "0.1.8"

  depends_on = [module.eks]

  account_id       = var.harness_account_id
  delegate_token   = harness_platform_delegatetoken.env[each.key].value
  delegate_name    = each.value.delegate_name
  namespace        = "${var.delegate_namespace_prefix}-${each.key}"
  manager_endpoint = var.harness_manager_endpoint
  delegate_image   = var.delegate_image
  replicas         = 1
  upgrader_enabled = true

  values = yamlencode({
    delegateTags = join(",", each.value.delegate_tags)
    description  = "Merck org delegate – ${each.key}"
    autoscaling = {
      enabled     = each.key != "prod"
      minReplicas = 1
      maxReplicas = each.key == "prod" ? 1 : 3
    }
  })
}
