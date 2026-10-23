provider "aws" {
  region = var.aws_region

  # Plan-only mode (plan_only = true) lets reviewers and CI run
  # `plan -refresh=false` without an AWS account: credentials are mocked and
  # the provider skips every call it would normally make during start-up.
  # Never set plan_only = true for a real apply.
  access_key                  = var.plan_only ? "mock-access-key" : null
  secret_key                  = var.plan_only ? "mock-secret-key" : null
  skip_credentials_validation = var.plan_only
  skip_requesting_account_id  = var.plan_only
  skip_metadata_api_check     = var.plan_only
  skip_region_validation      = var.plan_only

  default_tags {
    tags = local.tags
  }
}
