# Troubleshooting runbook

## 1. State drift

**What it is:** real infrastructure no longer matches state/config (someone changed a bucket in the console, a label was edited by another tool, a resource was deleted).

**Detect**
- HCP Terraform workspaces have `assessments_enabled = true`: scheduled health checks flag drift in the workspace UI and can notify Slack/email.
- Ad hoc: `terraform plan -refresh-only` shows what changed outside Terraform without proposing config changes.
- `terraform plan -detailed-exitcode` exits `2` when changes are pending (usable in a scheduled job).

**Decide, then act**
| Situation | Action |
|-----------|--------|
| Out-of-band change is wrong | `terraform apply` to revert it. |
| Out-of-band change is wanted | Update the code to match, then `plan` until clean. |
| Only state is stale (resource still correct) | `terraform apply -refresh-only` to accept real values into state. |
| Resource exists but is not in state | `terraform import` (or an `import {}` block) and add the matching code. |
| Resource renamed in code | `moved {}` block so Terraform does not destroy/recreate. |
| Resource should no longer be managed | `removed { lifecycle { destroy = false } }` block, then apply. |

Prevention: restrict console write access with IAM, enforce labels through OPA, and use `lifecycle { ignore_changes = [...] }` only for attributes another system legitimately owns.

## 2. Deployment failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Error 403: ... API has not been used in project ... or it is disabled` | API not enabled yet / propagation delay | Platform module enables APIs first; re-run after a minute. |
| `Error 409: ... bucket name is not available` | Bucket names are global | Names derive from `project_id`; if taken, change the suffix. |
| `Error 403: Permission denied` in a run | Run service account lacks a role | Grant the role to `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL`; check IAM audit logs. |
| `could not retrieve ... GCP credentials` | Dynamic credentials misconfigured | Check `TFC_GCP_*` variables, WIF attribute condition (workspace/org claim) and audience. |
| `permission denied` reading Vault | JWT role/policy mismatch | Verify `TFC_VAULT_RUN_ROLE`, bound claims, and that the policy allows `read` on `secret/data/gcp/<env>/app`. |
| `Error acquiring the state lock` | Another run holds the lock, or a run crashed | HCP: check/discard the running run. CLI: `terraform force-unlock <ID>` only after confirming nobody is running. |
| `Resource precondition failed` | Guardrail in the storage module | Read the message; do not bypass. |
| Run blocked by policy | OPA `deny` message | Message includes the resource address; fix code, push, re-run. Mandatory policies cannot be overridden. |
| `Inconsistent dependency lock file` | Lock file missing a platform | `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64` |

## 3. Configuration issues - quick checks

```bash
terraform fmt -check -recursive      # style
terraform validate                    # syntax and types
tflint --recursive                    # provider-aware lint
opa test policies/opa -v              # policy unit tests
TF_LOG=DEBUG terraform plan 2> debug.log   # provider/API detail (strip tokens before sharing)
terraform state list / state show <addr>   # what state believes
terraform console                     # evaluate expressions interactively
```

Never paste `debug.log` or state files into tickets without scrubbing: they may contain secrets.
