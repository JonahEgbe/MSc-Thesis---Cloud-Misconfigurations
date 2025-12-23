package main

# IAM-1: Block AdministratorAccess attachment (only for IAM domain)
deny contains msg if {
  applies_to_domain("IAM")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_role_policy_attachment"
  contains(lower(rc.change.after.policy_arn), "administratoraccess")

  msg := sprintf("IAM role policy attachment %s uses AdministratorAccess (NOT allowed)", [rc.address])
}

deny contains msg if {
  applies_to_domain("IAM")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_user_policy_attachment"
  contains(lower(rc.change.after.policy_arn), "administratoraccess")

  msg := sprintf("IAM user policy attachment %s uses AdministratorAccess (NOT allowed)", [rc.address])
}

# IAM-2: Inline policy wildcard action + wildcard resource (only for IAM domain)
deny contains msg if {
  applies_to_domain("IAM")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_role_policy"

  p := rc.change.after.policy
  is_string(p)
  pol := json.unmarshal(p)

  some j
  s := pol.Statement[j]
  allows_wildcard_action(s)
  allows_wildcard_resource(s)

  msg := sprintf("IAM inline policy %s allows Action='*' and Resource='*' (NOT allowed)", [rc.address])
}

deny contains msg if {
  applies_to_domain("IAM")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_policy"

  p := rc.change.after.policy
  is_string(p)
  pol := json.unmarshal(p)

  some j
  s := pol.Statement[j]
  allows_wildcard_action(s)
  allows_wildcard_resource(s)

  msg := sprintf("IAM managed policy %s allows Action='*' and Resource='*' (NOT allowed)", [rc.address])
}

# IAM-3: Trust policy principal '*' (only for IAM domain)
deny contains msg if {
  applies_to_domain("IAM")

  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_role"

  ap := rc.change.after.assume_role_policy
  is_string(ap)
  pol := json.unmarshal(ap)

  some j
  s := pol.Statement[j]
  s.Effect == "Allow"
  principal_is_star(s.Principal)

  msg := sprintf("IAM role %s trust policy allows Principal='*' (NOT allowed)", [rc.address])
}

############
# Helpers
############

allows_wildcard_action(stmt) if {
  a := stmt.Action
  is_string(a)
  a == "*"
}

allows_wildcard_action(stmt) if {
  a := stmt.Action
  is_array(a)
  a[_] == "*"
}

allows_wildcard_resource(stmt) if {
  r := stmt.Resource
  is_string(r)
  r == "*"
}

allows_wildcard_resource(stmt) if {
  r := stmt.Resource
  is_array(r)
  r[_] == "*"
}

principal_is_star(p) if {
  is_string(p)
  p == "*"
}

principal_is_star(p) if {
  is_object(p)
  some k
  v := p[k]
  is_string(v)
  v == "*"
}

principal_is_star(p) if {
  is_object(p)
  some k
  v := p[k]
  is_array(v)
  v[_] == "*"
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

