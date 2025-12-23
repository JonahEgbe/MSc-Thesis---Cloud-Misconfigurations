package main

# LOG-1: CloudTrail should exist (only for LOG domain)
deny contains msg if {
  applies_to_domain("LOG")
  not any_cloudtrail_present
  msg := "No aws_cloudtrail resource detected in plan (CloudTrail logging not enabled)"
}

# LOG-2: CloudTrail should be multi-region (only for LOG domain)
deny contains msg if {
  applies_to_domain("LOG")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_cloudtrail"
  rc.change.after.is_multi_region_trail == false

  msg := sprintf("CloudTrail %s is not multi-region (recommended TRUE)", [rc.address])
}

# LOG-3: CloudTrail should be enabled (only for LOG domain)
deny contains msg if {
  applies_to_domain("LOG")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_cloudtrail"
  rc.change.after.enable_logging == false

  msg := sprintf("CloudTrail %s has enable_logging=false (NOT allowed)", [rc.address])
}

############
# Helpers
############

any_cloudtrail_present if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_cloudtrail"
}

# Domain gating (detect domain from tags in plan)
applies_to_domain(d) if {
  domains := scenario_domains
  domains[d]
}

scenario_domains := {d |
  some i
  rc := input.resource_changes[i]
  after := rc.change.after
  d := extract_domain_from_after(after)
  d != ""
}

scenario_domains := {d |
  some i
  res := input.planned_values.root_module.resources[i]
  vals := res.values
  d := extract_domain_from_after(vals)
  d != ""
}

extract_domain_from_after(obj) := d if {
  is_object(obj)
  tags := obj.tags
  is_object(tags)
  d := tags.domain
  is_string(d)
} else := d if {
  is_object(obj)
  tags := obj.tags_all
  is_object(tags)
  d := tags.domain
  is_string(d)
} else := ""

