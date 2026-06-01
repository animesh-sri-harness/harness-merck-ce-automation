# Merck Chaos Engineering POC – Terraform Automation

Terraform POC for Merck's chaos engineering TSA architecture: Harness org/project/RBAC, per-env delegates, control EKS, IRSA role chain, and a tagged demo EC2 target.

## Architecture

```
Harness (Org Merck / Project App A)
  ├── Delegates: merck-delegate-dev | uat | prod
  ├── RBAC: App A Admin → HarnessDelegateRole, App A Dev → ChaosExecutionRole
  ├── Environments + infra: dev / uat / prod
  └── ChaosGuard: block destructive faults in UAT/Prod (manual UI step)

AWS Control Account (664418987337 – play account for POC)
  ├── EKS: merck-poc-chaos-control-cluster
  ├── IRSA: ksa-app-a-{env} → HarnessDelegateRole-{env}
  ├── STS:  HarnessDelegateRole-{env} → ChaosExecutionRole-{env}
  └── Demo EC2: merck-chaos-demo-dev (tag Chaos=allowed)
```

In production Merck uses **separate AWS accounts** per environment. This POC collapses them into one account but keeps the **same role names and AssumeRole chain**.

## Prerequisites

- Terraform >= 1.5
- AWS CLI with SSO profile `harness-impeng-play` (or update `aws_profile` in tfvars)
- Harness Platform API key (Account Admin)
- `kubectl` (optional, for verification)

## Quick start

```bash
# 1. AWS SSO
aws sso login --profile harness-impeng-play
export AWS_PROFILE=harness-impeng-play
export AWS_REGION=us-east-1

# 2. Configure secrets
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars: set harness_platform_api_key

# 3. Deploy
cd terraform
terraform init
terraform apply -var-file=terraform.tfvars

# 4. Verify
terraform output merck_tsa_compliance
terraform output chaos_demo_ec2
terraform output ec2_chaos_demo_steps
terraform output configure_kubectl
```

## What Terraform creates

| Layer | Resources |
|-------|-----------|
| **Harness** | Org Merck, Project App A, 3 envs/infra, 3 delegates, chaos infra, RBAC, AWS/K8s connectors |
| **AWS network** | VPC, public subnets |
| **AWS EKS** | Control cluster + 3-node group |
| **AWS IAM** | HarnessDelegateRole-{dev,uat,prod}, ChaosExecutionRole-{dev,uat,prod} |
| **AWS EC2** | Demo target `merck-chaos-demo-dev` (Chaos=allowed) |
| **Kubernetes** | Namespaces, KSAs with IRSA, chaos executor RBAC |

## Sample chaos experiments

### EC2 stop (AWS fault)

See `terraform output ec2_chaos_demo_steps`. Summary:

1. Project App A → Chaos → New Experiment
2. Environment: **DEV**, Infrastructure: **infra_dev**
3. Fault: **EC2 Stop By ID**, connector: **aws_dev**, region: **us-east-1**
4. Instance: output from `terraform output chaos_demo_ec2`

### Pod delete (Kubernetes fault)

1. Deploy a test pod: `kubectl run demo-nginx -n merck-chaos-dev --image=nginx`
2. Environment: **DEV**, Infrastructure: **infra_dev**
3. Fault: **Pod Delete** in namespace `merck-chaos-dev`

## Demonstrating AssumeRole in a single account

CloudTrail shows the full chain even without cross-account IDs:

1. `AssumeRoleWithWebIdentity` → HarnessDelegateRole-dev (IRSA from KSA)
2. `AssumeRole` → ChaosExecutionRole-dev
3. `StopInstances` on tagged EC2

See IAM trust policies on both roles in the AWS console.

## Key variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `aws_profile` | `harness-impeng-play` | SSO profile (no static keys needed) |
| `harness_delegate_iam_role_name` | `HarnessDelegateRole` | Control / IRSA role base name |
| `chaos_execution_iam_role_name` | `ChaosExecutionRole` | Target execution role base name |
| `create_chaos_demo_ec2` | `true` | Provision tagged demo EC2 |
| `create_chaos_guard` | `false` | Harness API often fails; configure in UI |

## Files

```
terraform/
  aws_eks.tf              # Control EKS cluster
  aws_network.tf          # VPC
  aws_iam.tf              # HarnessDelegateRole + ChaosExecutionRole chain
  aws_kubernetes.tf       # KSAs, namespaces, K8s RBAC
  aws_chaos_workload.tf   # Demo EC2 target
  harness_*.tf            # Harness org, envs, delegates, chaos, RBAC
  delegates_helm.tf       # Helm delegate installs
  providers.tf            # AWS SSO profile + EKS exec auth
  variables.tf
  outputs.tf
  terraform.tfvars.example
```

## Cleanup

```bash
cd terraform
terraform destroy -var-file=terraform.tfvars
```

Or set `create_chaos_demo_ec2 = false` to remove only the demo EC2.
