package main

# Deny any S3 bucket ACL that is "public-read"

#
# Case 1: Terraform HCL (.tf files) via the terraform input adapter
#
deny contains msg if {
  some name

  # All aws_s3_bucket_acl resources from the HCL
  acl := input.resource.aws_s3_bucket_acl[name]

  # ACL is public-read
  acl.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [hcl]", [name])
}

#
# Case 2: Terraform plan JSON (tfplan.json) – native JSON structure
#
deny contains msg if {
  some i

  rc := input.resource_changes[i]

  # Only look at S3 bucket ACL resources
  rc.type == "aws_s3_bucket_acl"

  # In the "after" state, the ACL is public-read
  rc.change.after.acl == "public-read"

  msg := sprintf("S3 bucket ACL %s is public-read (NOT allowed) [plan]", [rc.name])
}
