#!/usr/bin/env bash
# Evaluate the OPA guardrails locally against a plan before pushing.
#   ./scripts/policy-check.sh environments/dev
# Needs: terraform, opa, and credentials able to run `terraform plan`
# (for HCP-backed roots use `terraform plan -out=tfplan` via a CLI-driven run).
set -euo pipefail

dir="${1:?usage: policy-check.sh <environment-dir>}"

opa test policies/opa -v

(
  cd "$dir"
  terraform plan -out=tfplan.binary >/dev/null
  terraform show -json tfplan.binary > tfplan.json
)

violations=$(opa eval --format raw --data policies/opa --input "$dir/tfplan.json" \
  'data.terraform.gcp.deny')

rm -f "$dir/tfplan.binary" "$dir/tfplan.json"

if [ "$violations" != "[]" ]; then
  echo "Policy violations:" >&2
  echo "$violations" >&2
  exit 1
fi
echo "All policies passed."
