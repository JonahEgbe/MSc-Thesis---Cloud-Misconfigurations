package main

# NET-1: Security group allows SSH from the internet
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_security_group"

  some r
  ing := rc.change.after.ingress[r]
  cidr_allows_internet(ing.cidr_blocks)
  ing.from_port <= 22
  ing.to_port >= 22
  msg := sprintf("Security Group %s allows SSH (22) from 0.0.0.0/0 (NOT allowed)", [rc.address])
}

# NET-2: Security group allows RDP from the internet
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_security_group"

  some r
  ing := rc.change.after.ingress[r]
  cidr_allows_internet(ing.cidr_blocks)
  ing.from_port <= 3389
  ing.to_port >= 3389
  msg := sprintf("Security Group %s allows RDP (3389) from 0.0.0.0/0 (NOT allowed)", [rc.address])
}

# NET-3: Unrestricted egress (0.0.0.0/0, all protocols)
deny contains msg if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_security_group"

  some r
  eg := rc.change.after.egress[r]
  cidr_allows_internet(eg.cidr_blocks)
  eg.protocol == "-1"
  msg := sprintf("Security Group %s has unrestricted egress to 0.0.0.0/0 (review / high-risk)", [rc.address])
}

# NET-4: VPC flow logs missing (we flag if NO aws_flow_log is present in the plan)
deny contains msg if {
  not any_flow_logs_present
  msg := "No aws_flow_log resources detected in plan (VPC Flow Logs likely not enabled)"
}

############
# Helpers
############

cidr_allows_internet(c) if {
  is_array(c)
  c[_] == "0.0.0.0/0"
}

any_flow_logs_present if {
  some i
  rc := input.resource_changes[i]
  rc.type == "aws_flow_log"
}
