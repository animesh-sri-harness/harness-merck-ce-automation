# Merck Chaos Engineering – Terraform Automation

Modular Terraform for Merck's chaos engineering TSA architecture: Harness org/project/RBAC, per-environment delegates, control EKS, IRSA credential chain, and optional demo workloads.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Terraform | `>= 1.5.0` |
| AWS access | SSO profile or static credentials |
| Harness | Platform API key (PAT) with org/project permissions |
| Tools | `aws` CLI, `kubectl` (post-deploy verification) |

## Repository layout

```
.
├── README.md
└── terraform/
    ├── applications.tf          ← Harness projects (App A, B, …)
    ├── environments.tf          ← dev / uat / prod / staging
    ├── platform.tf              ← Org name, tags, IAM/K8s naming
    ├── main.tf
    ├── variables.tf             ← Secrets and feature flags
    ├── locals.tf
    ├── outputs.tf
    ├── providers.tf
    ├── versions.tf
    ├── modules/
    │   ├── harness/
    │   │   ├── org/
    │   │   └── application/
    │   └── aws/
    │       ├── control-plane/
    │       ├── delegate/
    │       ├── chaos-platform/
    │       ├── app-chaos/
    │       └── demo-workload/
    └── terraform.tfvars.example
```

## Quick start

```bash
aws sso login --profile harness-impeng-play
export AWS_PROFILE=harness-impeng-play

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Set harness_platform_api_key in terraform.tfvars

cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Configuration

| File | Purpose |
|------|---------|
| `applications.tf` | Harness projects, RBAC groups, demo EC2 |
| `environments.tf` | Deployment environments |
| `platform.tf` | Org identifier, AWS tags, IAM role names, ChaosGuard fault list |
| `terraform.tfvars` | Secrets, EKS sizing, feature flags (gitignored) |

### Add an environment

Edit `terraform/environments.tf`:

```hcl
staging = {
  harness_type      = "PreProduction"
  enable_chaos      = true
  chaos_guard_block = true
}
```

Run `terraform apply`. This provisions a delegate, Harness env/infra, IAM roles, and KSA for every application.

### Add an application

Edit `terraform/applications.tf`:

```hcl
app_b = {
  name             = "App B"
  slug             = "app_b"
  admin_group_name = "App B Admin"
  dev_group_name   = "App B Dev"
  admin_emails     = ["admin@example.com"]
  dev_emails       = ["dev@example.com"]
  create_demo_ec2  = false
}
```

### Platform settings

Edit `terraform/platform.tf` for org-wide defaults: `org`, `platform`, `default_tags`, and `chaos_guard_destructive_faults`.

## Architecture

| Layer | Scope | Module |
|-------|-------|--------|
| Harness org + delegates | Shared | `harness/org`, `aws/control-plane` |
| Harness project + chaos | Per app | `harness/application` |
| K8s namespaces | Per env | `aws/chaos-platform` |
| IAM + KSA + K8s RBAC | Per app × env | `aws/app-chaos` |
| Demo EC2 | Per app (optional) | `aws/demo-workload` |

**Credential chain:** KSA → `HarnessDelegateRole-{suffix}` → `ChaosExecutionRole-{suffix}` → tag-gated AWS faults (`Chaos=allowed`).

With one application, IAM suffix is `{env}`. With multiple applications, suffix becomes `{app_slug}-{env}`.

## Feature flags

Set in `terraform.tfvars`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `install_delegates` | `true` | Helm-deploy Harness delegates on control EKS |
| `create_aws_iam` | `true` | IRSA roles and tag-gated chaos policies |
| `create_rbac` | `true` | Harness user groups and role assignments |
| `create_chaos_guard` | `false` | ChaosGuard block rules (Harness API may fail) |

## Key outputs

```bash
terraform output applications_configured
terraform output environments_configured
terraform output merck_tsa_compliance
terraform output configure_kubectl
terraform output chaos_demo_ec2
terraform output ec2_chaos_demo_steps
terraform output harness_target_role_arns
```

## ChaosGuard

```bash
terraform apply -var-file=terraform.tfvars -var="create_chaos_guard=true"
```

Environments with `chaos_guard_block = true` in `environments.tf` are included in the block rule. If the Harness API returns an internal error, configure rules manually in **Project → Chaos → Security Governance**.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| AWS SSO expired | `aws sso login --profile <profile>` then `export AWS_PROFILE=<profile>` |
| Kubernetes unreachable during plan | Ensure SSO is active; cluster endpoint must be reachable |
| ChaosGuard apply fails | Set `create_chaos_guard = false` and configure in Harness UI |
| AWS faults blocked | Tag targets with `Chaos=allowed` (or values from `platform.tf`) |
| RBAC groups empty | Add emails to `admin_emails` / `dev_emails` in `applications.tf` |
