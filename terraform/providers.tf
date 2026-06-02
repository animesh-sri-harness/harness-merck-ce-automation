provider "harness" {
  endpoint         = var.harness_endpoint
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}

provider "aws" {
  region     = var.aws_region
  profile    = var.aws_profile != "" ? var.aws_profile : null
  access_key = var.aws_profile == "" ? var.aws_access_key_id : null
  secret_key = var.aws_profile == "" ? var.aws_secret_access_key : null
  token      = var.aws_profile == "" ? var.aws_session_token : null
}
