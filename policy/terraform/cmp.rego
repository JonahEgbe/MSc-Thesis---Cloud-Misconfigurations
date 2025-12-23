package main

# CMP-1: EC2 must enforce IMDSv2 (only for CMP domain)
deny contains msg if {
  applies_to_domain("CMP")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_instance"

  mo := rc.change.after.metadata_options
  not imdsv2_required(mo)

  msg := sprintf("EC2 %s does not enforce IMDSv2 (metadata_options.http_tokens must be 'required')", [rc.address])
}

# CMP-2: Root volume encryption should be enabled (only for CMP domain)
deny contains msg if {
  applies_to_domain("CMP")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_instance"

  rbd := rc.change.after.root_block_device
  has_root_block_device(rbd)
  not root_encrypted(rbd)

  msg := sprintf("EC2 %s root_block_device is not encrypted (recommended encrypted=true)", [rc.address])
}

# CMP-3: Detailed monitoring should be enabled (only for CMP domain)
deny contains msg if {
  applies_to_domain("CMP")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_instance"

  m := rc.change.after.monitoring
  m == false

  msg := sprintf("EC2 %s has detailed monitoring disabled (monitoring=false)", [rc.address])
}

############
# Helpers
############

imdsv2_required(mo) if {
  is_object(mo)
  mo.http_tokens == "required"
}

imdsv2_required(mo) if {
  is_array(mo)
  some i
  mo[i].http_tokens == "required"
}

has_root_block_device(rbd) if {
  is_object(rbd)
}

has_root_block_device(rbd) if {
  is_array(rbd)
  count(rbd) > 0
}

root_encrypted(rbd) if {
  is_object(rbd)
  rbd.encrypted == true
}

root_encrypted(rbd) if {
  is_array(rbd)
  some i
  rbd[i].encrypted == true
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

