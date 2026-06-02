output "org_id" {
  value = harness_platform_organization.this.id
}

output "delegate_tokens" {
  value     = { for k, v in harness_platform_delegatetoken.env : k => v.value }
  sensitive = true
}
