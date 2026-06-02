# Merck Chaos Engineering – Terraform Automation

Self-service Terraform for Merck engineering teams onboarding to Harness Chaos Engineering. Clone this repo, update config with your Harness account and per-environment AWS source/target accounts, and run `terraform apply` to provision Harness projects, cross-account IAM, and Harness chaos connectors/infrastructure.

## What this provisions

| Harness (your Harness account) | AWS |
|--------------------------------|-----|
| (Optional) Organization | **Source account (per env):** `HarnessDelegateRole-{env}` (IRSA on control EKS) |
| Project per application | **Target account (per env):** `ChaosExecutionRole-{env}` (tag-gated faults) |
| Environments (dev / uat / prod, …) | IRSA trust via source EKS OIDC (read-only lookup) |
| RBAC groups + roles | Cross-account `sts:AssumeRole` (delegate role → execution role) |
| AWS connectors (assume execution role in target) | |
| Chaos infrastructure (K8s v2) | |

**Merck model:** one control EKS cluster per environment in a **source** account (delegate installed there). Chaos faults run in a separate **target** account via `ChaosExecutionRole`.

**Credential chain:** chaos pod (KSA on source EKS, **created by Merck**) → `HarnessDelegateRole-{env}` (source, Terraform) → `ChaosExecutionRole-{env}` (target, Terraform) → tagged AWS resources.

---

## Before you begin

Collect the following before your first run.

### Harness

| Item | Where to get it |
|------|-----------------|
| **Account ID** | Harness UI → **Account Settings** → **Account Details** |
| **Platform API key (PAT)** | **Account Settings** → **Access Control** → **API Keys** — needs permissions to create orgs, projects, connectors, chaos resources |
| **User emails** | Harness login emails for admins (configure chaos) and developers (run experiments) |

### AWS

| Item | Where to get it |
|------|-----------------|
| **Source account(s)** | Per-environment AWS accounts hosting the control EKS cluster + `HarnessDelegateRole` |
| **Target account(s)** | Per-environment AWS accounts where `ChaosExecutionRole` is created for chaos faults |
| **SSO profile or credentials** | AWS CLI access with permissions for EKS, IAM, EC2, VPC |
| **Region** | e.g. `us-east-1` |

### Tools

Terraform `>= 1.5.0`, AWS CLI.

---

## First-time setup

### Step 1 — Clone and configure secrets

```bash
git clone https://github.com/animesh-sri-harness/harness-merck-ce-automation.git
cd harness-merck-ce-automation

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit **`terraform/terraform.tfvars`** with your values:

```hcl
harness_account_id       = "<your-harness-account-id>"
harness_platform_api_key = "<your-pat>"

# Merck default: org already exists
create_harness_org = false
harness_org_id     = "<existing-org-id>"

aws_region  = "us-east-1"
aws_profile = "<your-aws-sso-profile>"   # or use access keys in variables.tf

# Required for AWS IAM (IRSA trust policies):
# Provide per-environment source_eks_cluster_name in terraform/environments.tf
# Merck creates chaos namespaces + KSAs on source EKS separately (see chaos_service_accounts output)
```

Authenticate to AWS before every session:

```bash
aws sso login --profile <your-aws-sso-profile>
export AWS_PROFILE=<your-aws-sso-profile>
```

### Step 2 — Set your Harness org and platform naming

Edit defaults in **`terraform/variables.tf`** (or override in `terraform.tfvars`):

```hcl
org = {
  identifier = "merck"          # Harness org identifier (lowercase, no spaces)
  name       = "Merck"
  prefix     = "merck"          # Used for delegate names: {prefix}-delegate-dev
}

platform = {
  chaos_namespace_prefix = "merck-chaos"   # K8s namespaces: merck-chaos-dev, …
  chaos_allowed_tag_key  = "Chaos"
  chaos_allowed_tag_value = "allowed"      # Required on AWS targets for faults
  # …
}
```

Replace `merck` with your team's org prefix if deploying a dedicated org.

### Step 3 — Define your application(s)

Edit **`terraform/applications.tf`**. Each entry becomes one Harness **project**:

```hcl
app_a = {
  name             = "My Application"
  slug             = "my_app"              # Harness project identifier
  admin_group_name = "My App Admin"
  dev_group_name   = "My App Dev"
  admin_emails     = ["admin@merck.com"]   # HarnessDelegateRole users
  dev_emails       = ["dev@merck.com"]     # ChaosExecutionRole users
}
```

Add more applications by adding keys (`app_b`, `app_c`, …). Each app automatically gets every environment defined in `environments.tf`.

### Step 4 — Define your environments

Edit **`terraform/environments.tf`**. Each entry creates Harness environments, IAM roles, and (optionally) Kubernetes namespaces/KSAs for **all** applications.

For Merck’s model (one dedicated control EKS per environment, already provisioned), set source and target account IDs plus the control cluster name per environment:

```hcl
dev = {
  harness_type            = "PreProduction"
  enable_chaos            = true
  chaos_guard_block       = false
  source_account_id       = "111111111111"   # control EKS + HarnessDelegateRole-dev
  target_account_id       = "222222222222"   # ChaosExecutionRole-dev
  source_eks_cluster_name = "merck-chaos-dev-control"
  source_eks_region       = "us-east-1"      # optional; defaults to aws_region
}
uat = {
  harness_type            = "PreProduction"
  enable_chaos            = true
  chaos_guard_block       = true
  source_account_id       = "111111111111"
  target_account_id       = "333333333333"
  source_eks_cluster_name = "merck-chaos-uat-control"
}
prod = {
  harness_type            = "Production"
  enable_chaos            = true
  chaos_guard_block       = true
  source_account_id       = "444444444444"
  target_account_id       = "555555555555"
  source_eks_cluster_name = "merck-chaos-prod-control"
}
```

### Step 5 — Deploy

```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

First apply creates all infrastructure. Subsequent applies only change what you edit in the config files.

### Step 6 — Verify in Harness UI

After apply completes:

1. **Account → Delegates** — confirm environment delegates show **Connected** (Merck typically installs these outside Terraform)
2. **Org → your org → Projects** — open your project
3. **Access Control** — verify Admin and Dev groups and role bindings
4. **Environments** — dev / uat / prod environments and infrastructures exist
5. **Chaos Engineering → Infrastructures** — chaos infra registered per env
6. **Project Settings → Connectors** — K8s and AWS connectors present

```bash
terraform output post_apply_checklist
terraform output merck_tsa_compliance
```

### Step 7 — Verify in AWS

```bash
terraform output harness_control_role_arns
terraform output harness_target_role_arns
terraform output chaos_service_accounts   # KSA paths Merck must create on source EKS
```

Tag any AWS resource you want to fault with `Chaos=allowed` (or your configured tag key/value from `variables.tf`).

---

## Day-2: common changes

### Onboard a new application

1. Add a block to **`terraform/applications.tf`**
2. `terraform apply -var-file=terraform.tfvars`

Creates: Harness project, RBAC, env/infra, IAM roles, connectors for every existing environment.

### Add a new environment (e.g. staging)

1. Add a block to **`terraform/environments.tf`**
2. `terraform apply -var-file=terraform.tfvars`

Creates: Harness env/infra, IAM, connectors for **every** application. Merck manages delegates and KSAs on source EKS.

### Onboard new team members

Add Harness user emails to `admin_emails` or `dev_emails` in **`terraform/applications.tf`**, then apply. Users must already exist in your Harness account.

### Enable ChaosGuard (block destructive faults in UAT/Prod)

```bash
terraform apply -var-file=terraform.tfvars -var="create_chaos_guard=true"
```

Environments with `chaos_guard_block = true` are included. If the Harness API errors, configure manually under **Project → Chaos → Security Governance**.

---

## Configuration reference

| File | When to edit |
|------|--------------|
| **`terraform.tfvars`** | Secrets, AWS profile, feature flags (never commit) |
| **`applications.tf`** | Add/remove Harness projects, RBAC emails |
| **`environments.tf`** | Add/remove environments, ChaosGuard per env, target AWS accounts |
| **`variables.tf`** | Org name, IAM/K8s naming, default tags, ChaosGuard fault list |

### Feature flags (`terraform.tfvars`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `create_harness_org` | `false` | Create a Harness org (Merck typically uses an existing org) |
| `create_aws_iam` | `true` | Cross-account IAM roles (IRSA + tag-gated chaos policies) |
| `create_rbac` | `true` | Harness user groups and role assignments |
| `create_chaos_guard` | `false` | Automated ChaosGuard rules (enable when API is stable) |

### Key outputs

```bash
terraform output applications_configured
terraform output environments_configured
terraform output harness_projects
terraform output delegate_names
terraform output harness_target_role_arns
```

---

## Repository layout

```
terraform/
├── applications.tf       ← your Harness projects
├── environments.tf       ← your environments
├── variables.tf          ← org/platform defaults + all variable definitions
├── terraform.tfvars      ← your secrets (gitignored)
├── main.tf
└── modules/
    ├── harness/          org, application
    └── aws/              app-chaos
```

---

## Architecture

| Layer | Scope | Module / account |
|-------|-------|------------------|
| Harness org | Shared | `harness/org` |
| Harness project + chaos | Per app | `harness/application` |
| `HarnessDelegateRole-{env}` | Per app × env | `aws/app-chaos` → **source account** |
| `ChaosExecutionRole-{env}` | Per app × env | `aws/app-chaos` → **target account** |
| K8s namespace + KSA on source EKS | Per app × env | **Merck** (see `terraform output chaos_service_accounts`) |

With one application, IAM roles use suffix `{env}` (e.g. `HarnessDelegateRole-dev` in the dev source account, `ChaosExecutionRole-dev` in the dev target account). With multiple applications, suffix becomes `{app_slug}-{env}`.

Terraform uses per-environment AWS provider aliases (`aws.source_dev`, `aws.target_dev`, …). Set `aws_deploy_assume_role_arns` when applying from a central deployment account.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| AWS SSO expired | `aws sso login --profile <profile>` then `export AWS_PROFILE=<profile>` |
| Harness API 401/403 | Regenerate PAT; confirm account ID in `terraform.tfvars` |
| Delegate not Connected | Check EKS pods: `kubectl get pods -A \| grep delegate`; re-apply if needed |
| Kubernetes unreachable during plan | Ensure AWS credentials can `eks:DescribeCluster` in source accounts for OIDC lookup |
| ChaosGuard apply fails | Set `create_chaos_guard = false`; configure rules in Harness UI |
| AWS fault denied | Tag target with `Chaos=allowed` (or your `platform.chaos_allowed_tag_*` values) |
| RBAC groups empty | Add emails to `admin_emails` / `dev_emails` in `applications.tf` and apply |
| Users not in groups | Emails must match existing Harness account users |
