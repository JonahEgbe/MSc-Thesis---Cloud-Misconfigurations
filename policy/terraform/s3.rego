package main

# STO only

deny contains msg if {
  applies_to_domain("STO")

  some name
  acl := input.resource.aws_s3_bucket_acl[name]
  acl.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [hcl]", [name])
}

deny contains msg if {
  applies_to_domain("STO")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_s3_bucket_acl"
  rc.change.after.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [plan]", [rc.name])
}

deny contains msg if {
  applies_to_domain("STO")

  input.planned_values.root_module.resources

  some i
  resource := input.planned_values.root_module.resources[i]
  resource.type == "aws_s3_bucket_policy"

  policy_str := resource.values.policy
  is_string(policy_str)

  policy := json.unmarshal(policy_str)

  some j
  stmt := policy.Statement[j]
  stmt.Effect == "Allow"
  stmt.Principal == "*"

  msg := sprintf("S3 bucket policy %s allows Principal '*' (public access NOT allowed)", [resource.address])
}

deny contains msg if {
  applies_to_domain("STO")

  input.planned_values.root_module.resources

  some i
  resource := input.planned_values.root_module.resources[i]
  resource.type == "aws_s3_bucket_policy"

  policy := resource.values.policy
  is_object(policy)

  some j
  stmt := policy.Statement[j]
  stmt.Effect == "Allow"
  stmt.Principal == "*"

  msg := sprintf("S3 bucket policy %s allows Principal '*' (public access NOT allowed)", [resource.address])
}

deny contains msg if {
  applies_to_domain("STO")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_s3_bucket_policy"

  policy_str := rc.change.after.policy
  is_string(policy_str)

  policy := json.unmarshal(policy_str)

  some j
  stmt := policy.Statement[j]
  stmt.Effect == "Allow"
  stmt.Principal == "*"

  msg := sprintf("S3 bucket policy %s allows Principal '*' (public access NOT allowed)", [rc.address])
}

deny contains msg if {
  applies_to_domain("STO")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_s3_bucket_policy"

  policy := rc.change.after.policy
  is_object(policy)

  some j
  stmt := policy.Statement[j]
  stmt.Effect == "Allow"
  stmt.Principal == "*"

  msg := sprintf("S3 bucket policy %s allows Principal '*' (public access NOT allowed)", [rc.address])
}

############
# Helpers
############

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

