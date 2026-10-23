# Prod state lives in its own bucket (ideally in the prod AWS account) with its
# own key, isolated from dev. Only the CI deploy role and a few admins should
# have access to this bucket.
# S3 native locking (use_lockfile) prevents two applies running at once.
#
# Reviewing without AWS access? See README: scripts/tf-check.sh swaps this for
# a temporary local backend via a gitignored backend_override.tf.
terraform {
  backend "s3" {
    bucket       = "hotel-booking-tfstate-prod"
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
