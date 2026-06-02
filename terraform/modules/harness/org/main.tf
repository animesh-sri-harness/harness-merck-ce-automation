resource "harness_platform_organization" "this" {
  count = var.create_org ? 1 : 0

  identifier  = var.org.identifier
  name        = var.org.name
  description = "${var.org.name} organization – chaos engineering (Terraform)"
  tags        = var.tags_set

  lifecycle {
    prevent_destroy = true
  }
}

resource "harness_platform_delegatetoken" "env" {
  for_each = var.create_delegate_tokens ? var.environments : {}

  name       = "${each.key}-delegate-token"
  account_id = var.harness_account_id
  org_id     = var.create_org ? harness_platform_organization.this[0].id : var.existing_org_id

  lifecycle {
    prevent_destroy = true
  }
}
