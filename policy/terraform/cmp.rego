package main

# CMP-1: EC2 must enforce IMDSv2 (http_tokens = "required")
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_instance"

  mo := rc.change.after.metadata_options
  # If metadata_options missing OR http_tokens not required, flag
  not imdsv2_required(mo)

  msg := sprintf("EC2 %s does not enforce IMDSv2 (metadata_options.http_tokens must be 'required')", [rc.address])
}

# CMP-2: Root volume encryption should be enabled (if root_block_device exists and encrypted != true)
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_instance"

  rbd := rc.change.after.root_block_device
  has_root_block_device(rbd)
  not root_encrypted(rbd)

  msg := sprintf("EC2 %s root_block_device is not encrypted (recommended encrypted=true)", [rc.address])
}

# CMP-3: Detailed monitoring should be enabled (monitoring=true)
deny contains msg if {
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
  # sometimes TF provider renders nested blocks as arrays
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
