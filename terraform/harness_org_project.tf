resource "harness_platform_organization" "merck" {
  identifier  = local.org_id
  name        = var.org_name
  description = "Merck organization – chaos engineering POC (Terraform)"
  tags        = local.tags_set
}

resource "harness_platform_project" "app_a" {
  depends_on = [harness_platform_organization.merck]

  identifier  = local.project_id
  name        = var.project_name
  org_id      = harness_platform_organization.merck.id
  description = "Application A – dev / uat / prod chaos infrastructure definitions"
  tags        = local.tags_set
}
