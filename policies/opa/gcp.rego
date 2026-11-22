package terraform.gcp

import rego.v1

# Works with HCP Terraform (plan nested under input.plan) and with a raw
# `terraform show -json tfplan` document (resource_changes at the top level).
plan := object.get(input, "plan", input)

resource_changes := plan.resource_changes

# Resources being created or updated (the only ones with a meaningful "after").
active(rc) if {
	some action in rc.change.actions
	action in {"create", "update"}
}

allowed_locations := {"ASIA-SOUTH1", "ASIA-SOUTH2"}

required_labels := {"environment", "managed_by", "owner"}

# ---------------------------------------------------------------- Storage --
deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	active(rc)
	object.get(rc.change.after, "public_access_prevention", null) != "enforced"
	msg := sprintf("%s: GCS bucket must enforce public access prevention", [rc.address])
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	active(rc)
	object.get(rc.change.after, "uniform_bucket_level_access", null) != true
	msg := sprintf("%s: uniform bucket-level access must be enabled", [rc.address])
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	active(rc)
	not bucket_versioned(rc.change.after)
	msg := sprintf("%s: object versioning must be enabled", [rc.address])
}

bucket_versioned(after) if {
	some v in after.versioning
	v.enabled == true
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	active(rc)
	not upper(rc.change.after.location) in allowed_locations
	msg := sprintf("%s: bucket location %q is not an approved region", [rc.address, rc.change.after.location])
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	active(rc)
	missing := required_labels - object.keys(object.get(rc.change.after, "labels", {}))
	count(missing) > 0
	msg := sprintf("%s: missing required labels %v", [rc.address, sort(missing)])
}

# Prod buckets must never be deleted through a normal run.
deny contains msg if {
	some rc in resource_changes
	rc.type == "google_storage_bucket"
	"delete" in rc.change.actions
	object.get(object.get(rc.change.before, "labels", {}), "environment", "") == "prod"
	msg := sprintf("%s: deleting a prod bucket is not permitted", [rc.address])
}

# ---------------------------------------------------------------- Network --
deny contains msg if {
	some rc in resource_changes
	rc.type == "google_compute_network"
	active(rc)
	rc.change.after.auto_create_subnetworks == true
	msg := sprintf("%s: automatic subnet creation is prohibited", [rc.address])
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_compute_subnetwork"
	active(rc)
	count(object.get(rc.change.after, "log_config", [])) == 0
	msg := sprintf("%s: VPC flow logs must be enabled on every subnet", [rc.address])
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_compute_firewall"
	active(rc)
	rc.change.after.direction == "INGRESS"
	"0.0.0.0/0" in rc.change.after.source_ranges
	some rule in rc.change.after.allow
	risky_allow(rule)
	msg := sprintf("%s: ingress from 0.0.0.0/0 to all ports, SSH or RDP is prohibited", [rc.address])
}

risky_allow(rule) if rule.protocol == "all"

risky_allow(rule) if {
	some port in rule.ports
	port in {"22", "3389"}
}

# -------------------------------------------------------------------- IAM --
public_members := {"allUsers", "allAuthenticatedUsers"}

deny contains msg if {
	some rc in resource_changes
	rc.type in {
		"google_storage_bucket_iam_member",
		"google_project_iam_member",
		"google_secret_manager_secret_iam_member",
	}
	active(rc)
	rc.change.after.member in public_members
	msg := sprintf("%s: granting access to %s is prohibited", [rc.address, rc.change.after.member])
}

deny contains msg if {
	some rc in resource_changes
	rc.type in {"google_storage_bucket_iam_binding", "google_project_iam_binding"}
	active(rc)
	some member in rc.change.after.members
	member in public_members
	msg := sprintf("%s: granting access to %s is prohibited", [rc.address, member])
}

# Boolean verdict, for engines that evaluate an allow rule.
default allow := false

allow if count(deny) == 0
