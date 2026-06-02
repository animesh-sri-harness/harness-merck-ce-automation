resource "harness_platform_organization" "this" {
  identifier  = var.org.identifier
  name        = var.org.name
  description = "${var.org.name} organization – chaos engineering (Terraform)"
  tags        = var.tags_set
}

resource "harness_platform_delegatetoken" "env" {
  for_each = var.environments

  name       = "${each.key}-delegate-token"
  account_id = var.harness_account_id
  org_id     = harness_platform_organization.this.id
}
