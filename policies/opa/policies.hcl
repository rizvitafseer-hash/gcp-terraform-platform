# HCP Terraform policy-set manifest.
# NOTE: verify `query` semantics against the current HCP Terraform OPA docs for
# your organisation; adjust to `data.terraform.gcp.allow` if you prefer a
# boolean verdict over the `deny` message set.
policy "gcp_guardrails" {
  query             = "data.terraform.gcp.deny"
  enforcement_level = "mandatory"
}
