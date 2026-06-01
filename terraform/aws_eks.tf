# Merck control-plane EKS – minimal single-node group for delegates + chaos orchestration.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  # Cluster name is long; use fixed IAM role names (AWS name_prefix max 38 chars).
  iam_role_use_name_prefix = false
  iam_role_name            = "merck-poc-chaos-eks-role"

  # Required for Terraform/kubectl access without a separate aws-auth ConfigMap step.
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    control = {
      name           = "${var.name_prefix}-control"
      instance_types = [var.eks_node_instance_type]
      min_size       = var.eks_node_min_size
      max_size       = var.eks_node_max_size
      desired_size   = var.eks_node_desired_size

      iam_role_use_name_prefix = false
      iam_role_name            = "merck-poc-chaos-node-role"

      # Public subnets: nodes need outbound internet for Harness delegate + image pulls.
      subnet_ids = module.vpc.public_subnets
    }
  }

  tags = var.tags
}
