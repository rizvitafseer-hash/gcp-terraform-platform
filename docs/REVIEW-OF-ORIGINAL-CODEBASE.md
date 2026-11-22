# Review of the original `terraform-main` codebase

Findings are ordered by severity. "Fixed in" points at the new layout.

## Critical

| # | Finding | Fix |
|---|---------|-----|
| 1 | **`gitkey` is an OpenSSH private key committed in the repo** (with `gitkey.pub` for `rizvitafseer@gmail.com`). Anyone with the zip can authenticate as that key. | **Rotate now**: remove the public key from GitHub/GitLab, generate a new key, and purge the file from git history (`git filter-repo --path gitkey --invert-paths`). `.gitignore` now blocks it, `detect-private-key` and gitleaks run in pre-commit/CI. |
| 2 | `tfplan` (binary plan) is committed. Plan files embed resource attributes and can contain secrets. | Removed; `tfplan`/`*.tfplan` are git-ignored. |

## Broken configuration (would fail `init`/`validate`/`plan`)

| # | Finding | Fix |
|---|---------|-----|
| 3 | `enivironments/prod/main.tf` and `staging/main.tf` contain a lone `workspaces { ... }` block at top level: invalid HCL. | Full roots for all three environments under `environments/`. |
| 4 | Directory name typo `enivironments`. | `environments/`. |
| 5 | `modules/storage/outputs.tf.bak` references `google_storage_bucket.bucket` (resource is named `data`), and the `.bak` suffix means Terraform ignores it, so the module has **no outputs** and `outputs.tf.bak` at the root would fail too. | Real `outputs.tf` in every module and environment. |
| 6 | Root `main.tf` and `providers.tf` define a stray single-environment stack that conflicts with `environments/*` (duplicate `module "storage"`, a second `provider "google"` with hard-coded `us-central1`). | Removed. Providers are configured once per root module. |
| 7 | Root `variables.tf` declares `vault_address` with no default and `sensitive = true`, but nothing sets it and no Vault provider exists, so Vault was never integrated. A URL is not a secret and marking it sensitive hides it in plans/outputs. | Superseded: Vault removed; the app secret is read from GCP Secret Manager (`app-seceret`). |

## Security / policy gaps

| # | Finding | Fix |
|---|---------|-----|
| 8 | Hard-coded real project ID (`project-3d116623-...`) in `providers.tf` and the bucket name. | `project_id` now lives in each environment's `terraform.tfvars`. |
| 9 | Root `secure_data` bucket lacks `public_access_prevention`, labels, and uses location `US`. It violates the repo's own OPA policy. | Single hardened storage module; policy enforces it. |
| 10 | OPA bug: `resource.change.after.x != "enforced"` is *undefined* (rule does not fire) when the attribute is absent, and `after` is `null` on deletes. Non-compliant buckets can slip through. | `object.get(..., null)` plus an `active()` helper; 11 unit tests. |
| 11 | Policy was never wired to anything (no policy set, no tests, no CI). | OPA policy + unit tests, run via `scripts/policy-check.sh` (wire `opa test` into your CI). |
| 12 | Network module had a `labels` variable that was never used, no firewall posture. | Default-deny ingress, internal allow, IAP-only SSH, flow logs. |

## Design / maintainability

| # | Finding | Fix |
|---|---------|-----|
| 13 | `lifecycle { prevent_destroy = true }` hard-coded inside the storage module makes **every** environment's bucket impossible to tear down, which breaks reuse (dev/sandbox). Lifecycle meta-arguments cannot be variables. | Removed from the module. Protection is layered: `force_destroy = false`, a `precondition` blocking `force_destroy` in prod, an OPA rule denying prod bucket deletion, and `prevent_destroy` kept only on the state bucket. |
| 14 | Bucket lifecycle rule `age = 90 -> Delete` deletes **live objects** after 90 days, which is silent data loss despite versioning being on. | Rule now targets only `ARCHIVED` (noncurrent) versions. |
| 15 | Two competing state strategies (a GCS state bucket *and* a `cloud {}` block). One configuration can use only one backend. | GCS is the only backend; `bootstrap/state-bucket` creates the bucket. |
| 16 | `terraform.tfvars` is git-ignored, yet one ships in `dev/` with placeholders, so teammates can't reproduce it. | Non-secret `terraform.tfvars` committed per environment; ignore rules target real secret files only. |
| 17 | `.terraform.lock.hcl` only locks `google`; `required_version >= 1.0.0` is very loose; CRLF line endings. | Version constraints tightened, `.gitattributes` forces LF. Regenerate the lock file per root (see README). |
| 18 | Environment-specific code duplicated; modules lacked validation, no `depends_on`/API enablement, no data sources. | `modules/platform` composition module, API enablement, `google_project` data source, validations, pre/postconditions. |
