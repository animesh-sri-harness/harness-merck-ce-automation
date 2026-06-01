# Org-level delegate tokens – one per environment delegate (Merck: 3 delegates in org).
resource "harness_platform_delegatetoken" "env" {
  for_each = local.environments

  name       = "${each.key}-delegate-token"
  account_id = var.harness_account_id
  org_id     = harness_platform_organization.merck.id
}
