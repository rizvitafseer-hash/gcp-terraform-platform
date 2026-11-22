# GCP Terraform Platform

Modular, multi-environment Terraform for GCP, run through HCP Terraform, with Vault-managed secrets, OPA policy as code and CI.

## Architecture

```
Developer -> Pull request -> GitHub Actions (fmt, validate, tflint, trivy, gitleaks, opa test)
                          -> HCP Terraform speculative plan + OPA policy check
Merge to main -> HCP Terraform run per workspace
                  dev: auto-apply | staging/prod: manual approval
                  creds: GCP via workload identity federation, Vault via JWT (no static keys)
                  state: HCP-managed, encrypted, versioned, locked per run
```

```
.
├── modules/
│   ├── network/    VPC, subnet (flow logs), default-deny + internal + IAP-SSH firewall
│   ├── storage/    hardened GCS bucket (PAP enforced, UBLA, versioning, CMEK optional)
│   └── platform/   composition: APIs -> network, storage, service account, IAM, Vault->Secret Manager
├── environments/
│   ├── dev/ staging/ prod/   thin roots: backend (cloud block), providers, values
├── hcp-terraform/  workspaces, variables, variable set, OPA policy set (as code)
├── policies/opa/   Rego guardrails + unit tests + policy-set manifest
├── bootstrap/state-bucket/   OPTIONAL GCS state bucket (only for gcs-backend use)
├── .github/workflows/terraform-ci.yml
├── docs/           review of the original code, troubleshooting runbook
└── scripts/policy-check.sh   local plan-vs-policy check
```

## Requirement coverage

| Requirement | Where |
|-------------|-------|
| Providers, resources, data sources, variables, locals, outputs | `modules/*`, `environments/*` (`data.google_project`, `data.vault_kv_secret_v2`, `locals` in `platform`) |
| Reusable modules | `network`, `storage`, composed by `platform` |
| Multiple environments | `environments/{dev,staging,prod}`, one HCP workspace each, non-overlapping CIDRs |
| Dependencies & lifecycle | implicit refs + explicit `depends_on` on API enablement; `precondition`/`postcondition`; `prevent_destroy` on the state bucket; `moved`/`removed` guidance in the runbook |
| Remote state + locking | HCP Terraform (default). `bootstrap/state-bucket` + `backend "gcs"` is the alternative (native locking). One backend per root. |
| HCP Terraform workspaces, variables, remote runs | `hcp-terraform/` |
| Git + CI/CD | VCS-driven workspaces + GitHub Actions |
| Secrets via Vault | Vault provider with HCP-issued token; secret copied to Secret Manager; no secrets in code or tfvars |
| Policy as code | `policies/opa/gcp.rego` (+ tests) attached as mandatory policy set |
| Standards | pinned versions, validations, descriptions on all variables/outputs, fmt/tflint/pre-commit, LF endings |
| Drift / failure troubleshooting | `assessments_enabled`, `docs/TROUBLESHOOTING.md` |

## Getting started

**Prerequisites (one time, outside Terraform)**
1. GCP: one project per environment; a Workload Identity pool/provider trusting HCP Terraform (`app.terraform.io`, with an attribute condition on your org); a run service account per project with the roles needed (`compute.networkAdmin`, `storage.admin`, `iam.serviceAccountAdmin`, `serviceusage.serviceUsageAdmin`, `secretmanager.admin`, `resourcemanager.projectIamAdmin` as required).
2. Vault: JWT auth method trusting HCP Terraform, a role (default `tfc-gcp`) bound to your org/workspaces, and a policy allowing `read` on `secret/data/gcp/<env>/app`. Seed the secrets, e.g. `vault kv put -mount=secret gcp/dev/app db_password=...`.
3. HCP Terraform: org, VCS connection, and a token (`TFE_TOKEN`).

**Create workspaces**
```bash
cd hcp-terraform
cp terraform.tfvars.example terraform.tfvars   # fill in (git-ignored pattern: keep real values out of git)
terraform init && terraform apply
```

**Per environment**
- Edit `environments/<env>/terraform.tfvars` (`vault_address`, CIDR, Vault path).
- Set `TF_CLOUD_ORGANIZATION=<org>` for local CLI use.
- Generate cross-platform lock files and commit them:
  `terraform -chdir=environments/dev init && terraform -chdir=environments/dev providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`

**Promotion flow:** change code on a branch -> PR (CI + speculative plans) -> merge -> dev auto-applies -> approve staging -> approve prod.

**Using GCS instead of HCP state:** apply `bootstrap/state-bucket`, replace the `cloud {}` block in an environment with `backend "gcs" { bucket = "<name>" prefix = "env/dev" }`, and run `terraform init -migrate-state`.

## Things to know

- **Secrets in state.** `secret_data` written to Secret Manager lands in state (encrypted at rest in HCP, masked in output). Restrict workspace state access, or move to write-only arguments if your provider/Terraform versions support them.
- **Policy query semantics.** Confirm `policies/opa/policies.hcl` `query` against the current HCP OPA documentation for your organisation.
- **Prod deletion protection** is policy-based (OPA + `force_destroy=false` + precondition), not `prevent_destroy`, so the module stays reusable.
- **Not run against GCP.** This was authored without a Terraform/OPA binary available; run `terraform validate`, `opa test policies/opa` and a first `plan` in dev before relying on it. CI does this on every PR.
