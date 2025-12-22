package main

# IAM-1: Block AdministratorAccess attachment (managed policy)
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_role_policy_attachment"
  contains(lower(rc.change.after.policy_arn), "administratoraccess")
  msg := sprintf("IAM role policy attachment %s uses AdministratorAccess (NOT allowed)", [rc.address])
}

deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_iam_user_policy_attachment"
  contains(lower(rc.change.after.policy_arn), "administratoraccess")
  msg := sprintf("IAM user policy attachment %s uses AdministratorAccess (NOT allowed)", [rc.address])
}

# IAM-2: Inline policy with wildcard action AND wildcard resource (high-risk)
deny contains msg if {
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

# IAM-3: AssumeRole policy with overly broad principal (Principal="*")
deny contains msg if {
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
  # Common shapes: {"AWS":"*"} or {"Service":"*"}
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
