data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs                     = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets          = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access           = true
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  iam_role_use_name_prefix = false
  iam_role_name            = coalesce(var.eks_cluster_iam_role_name, "${var.name_prefix}-eks-role")

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    control = {
      name                     = "${var.name_prefix}-control"
      instance_types           = [var.eks_node_instance_type]
      min_size                 = var.eks_node_min_size
      max_size                 = var.eks_node_max_size
      desired_size             = var.eks_node_desired_size
      iam_role_use_name_prefix = false
      iam_role_name            = coalesce(var.eks_node_iam_role_name, "${var.name_prefix}-node-role")
      subnet_ids               = module.vpc.public_subnets
    }
  }

  tags = var.tags
}

resource "kubernetes_namespace" "chaos_control" {
  metadata {
    name = var.chaos_control_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "customer"                     = lookup(var.tags, "customer", "merck")
    }
  }
}

module "delegate" {
  for_each = var.install_delegates ? var.environments : {}

  source = "../delegate"

  account_id       = var.harness_account_id
  delegate_token   = var.delegate_tokens[each.key]
  delegate_name    = each.value.delegate_name
  namespace        = "${var.delegate_namespace_prefix}-${each.key}"
  manager_endpoint = var.harness_manager_endpoint
  delegate_image   = var.delegate_image
  replicas         = 1
  upgrader_enabled = true

  values = yamlencode({
    delegateTags = join(",", each.value.delegate_tags)
    description  = "Org delegate – ${each.key}"
    autoscaling = {
      enabled     = false
      minReplicas = 1
      maxReplicas = 1
    }
  })
}
