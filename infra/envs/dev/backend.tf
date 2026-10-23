# Dev state lives in its own bucket and key, separate from prod, so a dev
# change can never read or overwrite prod state.
# S3 native locking (use_lockfile) prevents two applies running at once.
#
# Reviewing without AWS access? See README: scripts/tf-check.sh swaps this for
# a temporary local backend via a gitignored backend_override.tf.
terraform {
  backend "s3" {
    bucket       = "hotel-booking-tfstate-dev"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
