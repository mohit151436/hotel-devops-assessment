#!/usr/bin/env bash
# Runs the same Terraform checks as the reviewers and CI, without AWS access:
#   fmt -> init -> validate -> plan -refresh=false
#
# Usage: ./scripts/tf-check.sh [dev|prod]      (default: dev)
#        TF_BIN=tofu ./scripts/tf-check.sh dev  (use OpenTofu instead)
#
# How it works without AWS:
#   * A temporary, gitignored backend_override.tf switches the S3 backend to a
#     local one, so `init` does not need the state bucket.
#   * -var plan_only=true makes the provider use mock credentials and skip its
#     start-up API calls. With -refresh=false, plan makes no AWS calls at all.
set -euo pipefail

ENVIRONMENT="${1:-dev}"
TF="${TF_BIN:-terraform}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT_DIR}/infra/envs/${ENVIRONMENT}"

if [[ ! -d "${ENV_DIR}" ]]; then
  echo "ERROR: unknown environment '${ENVIRONMENT}' (expected dev or prod)" >&2
  exit 1
fi

command -v "${TF}" >/dev/null 2>&1 || { echo "ERROR: '${TF}' not found in PATH" >&2; exit 1; }

cd "${ENV_DIR}"

cleanup() { rm -f backend_override.tf; }
trap cleanup EXIT

cat > backend_override.tf <<'HCL'
# Temporary local backend for plan-only review. Created and removed by
# scripts/tf-check.sh. Never commit this file.
terraform {
  backend "local" {
    path = ".plan-only/terraform.tfstate"
  }
}
HCL

echo "==> [${ENVIRONMENT}] terraform fmt -check"
"${TF}" fmt -check -recursive -diff "${ROOT_DIR}/infra"

echo "==> [${ENVIRONMENT}] terraform init (local backend override)"
"${TF}" init -input=false -reconfigure

echo "==> [${ENVIRONMENT}] terraform validate"
"${TF}" validate

echo "==> [${ENVIRONMENT}] terraform plan -refresh=false (plan-only mode)"
"${TF}" plan -refresh=false -input=false -lock=false -var plan_only=true -out=tfplan
"${TF}" show -no-color tfplan > plan.txt

echo
echo "OK: ${ENVIRONMENT} passed fmt, init, validate and plan."
echo "    Plan summary: $(grep -E '^Plan:' plan.txt || echo 'see plan.txt')"
echo "    Full plan:    infra/envs/${ENVIRONMENT}/plan.txt"
