package main

#
# Case 1: HCL mode — Detect public ACLs
#
deny contains msg if {
  some name
  acl := input.resource.aws_s3_bucket_acl[name]
  acl.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [hcl]", [name])
}

#
# Case 2: Plan JSON mode — Detect public ACLs via resource_changes
#
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_s3_bucket_acl"
  rc.change.after.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [plan]", [rc.name])
}

#
# Case 3: Plan JSON mode — Detect bucket policy Principal="*" (STRING format)
# Handles when policy is a JSON string that needs unmarshaling
#
deny contains msg if {
  input.planned_values.root_module.resources

  some i
  resource := input.planned_values.root_module.resources[i]
  resource.type == "aws_s3_bucket_policy"

  policy_str := resource.values.policy
  is_string(policy_str)
  
  # Parse the JSON string
  policy := json.unmarshal(policy_str)
  
  some j
  stmt := policy.Statement[j]
  stmt.Effect == "Allow"
  stmt.Principal == "*"

  msg := sprintf(
    "S3 bucket policy %s allows Principal '*' (public access NOT allowed)",
    [resource.address],
  )
}

#
# Case 4: Plan JSON mode — Detect bucket policy Principal="*" (OBJECT format)
# Handles when policy is already a parsed object
#
deny contains msg if {
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

  msg := sprintf(
    "S3 bucket policy %s allows Principal '*' (public access NOT allowed)",
    [resource.address],
  )
}

#
# Case 5: resource_changes mode — Detect bucket policy Principal="*" (STRING)
#
deny contains msg if {
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

#
# Case 6: resource_changes mode — Detect bucket policy Principal="*" (OBJECT)
#
deny contains msg if {
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
