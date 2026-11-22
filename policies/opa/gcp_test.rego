package terraform.gcp_test

import rego.v1

import data.terraform.gcp

good_bucket := {
	"address": "module.storage.google_storage_bucket.data",
	"type": "google_storage_bucket",
	"change": {
		"actions": ["create"],
		"after": {
			"location": "ASIA-SOUTH1",
			"public_access_prevention": "enforced",
			"uniform_bucket_level_access": true,
			"versioning": [{"enabled": true}],
			"labels": {"environment": "dev", "managed_by": "terraform", "owner": "platform-team"},
		},
	},
}

test_compliant_bucket_passes if {
	count(gcp.deny) == 0 with input as {"resource_changes": [good_bucket]}
}

test_nested_plan_input_is_supported if {
	count(gcp.deny) == 0 with input as {"plan": {"resource_changes": [good_bucket]}}
}

test_missing_public_access_prevention_denied if {
	bad := json.patch(good_bucket, [{"op": "remove", "path": "/change/after/public_access_prevention"}])
	count(gcp.deny) > 0 with input as {"resource_changes": [bad]}
}

test_wrong_region_denied if {
	bad := json.patch(good_bucket, [{"op": "replace", "path": "/change/after/location", "value": "US"}])
	some msg in gcp.deny with input as {"resource_changes": [bad]}
	contains(msg, "approved region")
}

test_missing_labels_denied if {
	bad := json.patch(good_bucket, [{"op": "replace", "path": "/change/after/labels", "value": {"environment": "dev"}}])
	some msg in gcp.deny with input as {"resource_changes": [bad]}
	contains(msg, "missing required labels")
}

test_prod_bucket_delete_denied if {
	deleting := {
		"address": "module.storage.google_storage_bucket.data",
		"type": "google_storage_bucket",
		"change": {
			"actions": ["delete"],
			"before": {"labels": {"environment": "prod"}},
			"after": null,
		},
	}
	some msg in gcp.deny with input as {"resource_changes": [deleting]}
	contains(msg, "prod bucket")
}

test_dev_bucket_delete_allowed if {
	deleting := {
		"address": "module.storage.google_storage_bucket.data",
		"type": "google_storage_bucket",
		"change": {
			"actions": ["delete"],
			"before": {"labels": {"environment": "dev"}},
			"after": null,
		},
	}
	count(gcp.deny) == 0 with input as {"resource_changes": [deleting]}
}

test_auto_subnets_denied if {
	vpc := {
		"address": "google_compute_network.vpc",
		"type": "google_compute_network",
		"change": {"actions": ["create"], "after": {"auto_create_subnetworks": true}},
	}
	count(gcp.deny) > 0 with input as {"resource_changes": [vpc]}
}

test_open_ssh_firewall_denied if {
	fw := {
		"address": "google_compute_firewall.ssh",
		"type": "google_compute_firewall",
		"change": {
			"actions": ["create"],
			"after": {
				"direction": "INGRESS",
				"source_ranges": ["0.0.0.0/0"],
				"allow": [{"protocol": "tcp", "ports": ["22"]}],
			},
		},
	}
	count(gcp.deny) > 0 with input as {"resource_changes": [fw]}
}

test_iap_ssh_firewall_allowed if {
	fw := {
		"address": "google_compute_firewall.iap",
		"type": "google_compute_firewall",
		"change": {
			"actions": ["create"],
			"after": {
				"direction": "INGRESS",
				"source_ranges": ["35.235.240.0/20"],
				"allow": [{"protocol": "tcp", "ports": ["22"]}],
			},
		},
	}
	count(gcp.deny) == 0 with input as {"resource_changes": [fw]}
}

test_public_iam_member_denied if {
	iam := {
		"address": "google_storage_bucket_iam_member.public",
		"type": "google_storage_bucket_iam_member",
		"change": {"actions": ["create"], "after": {"member": "allUsers"}},
	}
	count(gcp.deny) > 0 with input as {"resource_changes": [iam]}
}
