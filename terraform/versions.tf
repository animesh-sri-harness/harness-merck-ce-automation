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
  }
}
