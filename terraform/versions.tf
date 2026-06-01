terraform {
  required_version = ">= 1.5.0"

  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.42"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
}
