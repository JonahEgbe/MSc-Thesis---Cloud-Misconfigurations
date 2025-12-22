package main

# LOG-1: CloudTrail should exist (flag if none in plan)
deny contains msg if {
  not any_cloudtrail_present
  msg := "No aws_cloudtrail resource detected in plan (CloudTrail logging not enabled)"
}

# LOG-2: CloudTrail should be multi-region (if CloudTrail exists and is false)
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_cloudtrail"
  rc.change.after.is_multi_region_trail == false
  msg := sprintf("CloudTrail %s is not multi-region (recommended TRUE)", [rc.address])
}

# LOG-3: CloudTrail should be enabled
deny contains msg if {
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
