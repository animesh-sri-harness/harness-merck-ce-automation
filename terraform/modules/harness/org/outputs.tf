output "org_id" {
  value = var.create_org ? harness_platform_organization.this[0].id : var.existing_org_id
}

output "delegate_tokens" {
  value = var.create_delegate_tokens ? {
    for k, v in harness_platform_delegatetoken.env : k => v.value
  } : {}
  sensitive = true
}
