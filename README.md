# GCP Terraform Platform

Modular, multi-environment Terraform for GCP with remote state in GCS, secrets in GCP Secret Manager and OPA policy as code.

No HCP Terraform and no Vault: state lives in a GCS bucket and the application secret lives in Secret Manager.

## Layout

```
.
├── modules/
│   ├── network/    VPC, subnet (flow logs), default-deny + internal + IAP-SSH firewall
│   ├── storage/    hardened GCS bucket (PAP enforced, UBLA, versioning, CMEK optional)
│   └── platform/   composition: APIs -> network, storage, service account, IAM, Secret Manager access
├── environments/
│   └── dev/ staging/ prod/   thin roots: gcs backend, provider, values
├── policies/opa/   Rego guardrails + unit tests
├── bootstrap/state-bucket/   creates the GCS state bucket (apply once)
├── docs/           review of the original code, troubleshooting runbook
└── scripts/policy-check.sh   local plan-vs-policy check
```

## Project and secret

| Setting | Value |
|---------|-------|
| Project | `project-3d116623-b2e3-4d71-83e` |
| Secret | `app-seceret` (existing; the spelling matches the console) |
| State bucket | `project-3d116623-b2e3-4d71-83e-terraform-state` |

The secret is **not created or read by Terraform**. The platform module only looks it up and grants each environment's app service account `roles/secretmanager.secretAccessor` on it. The value never enters code, tfvars or state; the app reads it at runtime:

```bash
gcloud secrets versions access latest --secret=app-seceret \
  --project=project-3d116623-b2e3-4d71-83e
```

Set `app_secret_id = null` in an environment's `terraform.tfvars` to disable this.

All three environments currently point at the same project. Resource names include the environment (`ent-dev-vpc`, `<project>-dev-data`, ...), so they do not collide. Change `project_id` per environment when you get separate projects.

## Getting started

1. **Auth:** `gcloud auth application-default login` (the identity needs roles to manage compute, storage, IAM, service usage and Secret Manager IAM in the project).
2. **State bucket (once):**
   ```bash
   cd bootstrap/state-bucket
   terraform init && terraform apply
   ```
3. **Each environment:**
   ```bash
   cd environments/dev
   terraform init
   terraform plan
   terraform apply
   ```
   Then commit the generated lock file:
   `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64`
4. **Policy check before pushing:** `./scripts/policy-check.sh environments/dev`

## Things to know

- **State bucket bootstrap.** The bootstrap root uses local state; keep that small state file safe or import the bucket later.
- **Prod deletion protection** is policy-based (OPA + `force_destroy=false` + precondition), not `prevent_destroy`, so the module stays reusable.
- **Not run against GCP.** Authored without Terraform/OPA binaries; run `terraform validate`, `opa test policies/opa` and a first `plan` in dev before relying on it.
